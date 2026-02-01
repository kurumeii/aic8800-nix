# AIC8800D80 Linux Driver - NixOS

This driver is for the AIC8800D80 chipset, supported by devices such as the Tenda U11 and AX913B.

**This version is specifically configured for NixOS.**

Added support for devices with Vendor ID 368B (tested).

Bluetooth not working.

## Quick Start

### Prerequisites

- NixOS system with kernel 6.1 or newer
- Flakes enabled (for flake-based installation)

### Installation (Choose One Method)

#### Option A: With Flakes (Recommended)

1. Add to your `flake.nix`:
```nix
{
  inputs.aic8800.url = "github:kurumeii/aic8800-nix";
  
  outputs = { nixpkgs, aic8800, ... }: {
    nixosConfigurations.your-hostname = nixpkgs.lib.nixosSystem {
      modules = [
        aic8800.nixosModules.default
        {
          hardware.aic8800.enable = true;
        }
      ];
    };
  };
}
```

2. Rebuild:
```bash
sudo nixos-rebuild switch
```

#### Option B: Direct Import

1. Clone this repo:
```bash
git clone https://github.com/kurumeii/aic8800-nix.git /etc/nixos/aic8800d80
```

2. Add to `configuration.nix`:
```nix
{
  imports = [ ./aic8800d80/module.nix ];
  hardware.aic8800.enable = true;
}
```

3. Rebuild:
```bash
sudo nixos-rebuild switch
```

### Verify

```bash
# Check module loaded
lsmod | grep aic8800

# Check USB device
lsusb | grep -E "(3020|368b)"

# Check WiFi interface
ip link show

# Connect to WiFi
nmcli device wifi connect "SSID" password "PASSWORD"
```

### Quick Troubleshooting

**Module not loading?**
```bash
sudo modprobe aic8800_fdrv
sudo dmesg | grep aic8800
```

**After kernel update?**
```bash
sudo nixos-rebuild switch  # Automatically rebuilds driver
```

**Complete removal?**
```nix
{ hardware.aic8800.enable = false; }  # Then rebuild
```

---

## Detailed Documentation

### All Installation Methods

#### Method 1: Using Flakes (Recommended)

1. **Add the flake to your configuration:**

   Edit your `/etc/nixos/flake.nix`:

   ```nix
   {
     inputs = {
       nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
       aic8800.url = "github:shenmintao/aic8800d80";
       # Or use a local path:
       # aic8800.url = "path:/path/to/aic8800d80";
     };

     outputs = { self, nixpkgs, aic8800, ... }: {
       nixosConfigurations.your-hostname = nixpkgs.lib.nixosSystem {
         system = "x86_64-linux";
         modules = [
           ./configuration.nix
           aic8800.nixosModules.default
         ];
       };
     };
   }
   ```

2. **Enable the driver in your configuration:**

   Add to your `/etc/nixos/configuration.nix`:

   ```nix
   {
     hardware.aic8800.enable = true;
   }
   ```

3. **Rebuild your system:**

   ```bash
   sudo nixos-rebuild switch
   ```

#### Method 2: Direct Module Import (Without Flakes)

1. **Clone this repository:**

   ```bash
   git clone https://github.com/kurumeii/aic8800-nix.git /etc/nixos/aic8800d80
   ```

2. **Import the module in your configuration:**

   Edit your `/etc/nixos/configuration.nix`:

   ```nix
   { config, pkgs, ... }:

   {
     imports = [
       ./aic8800d80/module.nix
     ];

     hardware.aic8800.enable = true;

     # ... rest of your configuration
   }
   ```

3. **Rebuild your system:**

   ```bash
   sudo nixos-rebuild switch
   ```

#### Method 3: Manual Package Build

If you prefer to build the package separately:

```nix
{ config, pkgs, ... }:

let
  aic8800-driver = config.boot.kernelPackages.callPackage /path/to/aic8800d80/default.nix { };
in
{
  boot.extraModulePackages = [ aic8800-driver ];
  boot.kernelModules = [ "aic8800_fdrv" ];
  hardware.firmware = [ aic8800-driver ];
}
```

### Configuration Options

The NixOS module provides several configuration options:

```nix
{
  hardware.aic8800 = {
    # Enable the driver (required)
    enable = true;

    # Specify a custom driver package (optional)
    # package = pkgs.callPackage ./custom-aic8800.nix { };

    # Auto-load module at boot (default: true)
    autoload = true;
  };
}
```

### Verify Installation

After rebuilding your system:

1. **Check if the module is loaded:**

   ```bash
   lsmod | grep aic8800
   ```

   You should see:
   ```
   aic8800_fdrv
   aic_load_fw
   ```

2. **Connect your USB WiFi adapter and check kernel logs:**

   ```bash
   sudo dmesg | grep -i aic8800
   ```

3. **Check for wireless interfaces:**

   ```bash
   ip link show
   # or
   iwconfig
   ```

4. **Scan for WiFi networks:**

   ```bash
   nmcli device wifi list
   ```

5. **Connect to a network:**

   ```bash
   nmcli device wifi connect "SSID" password "PASSWORD"
   ```

### Troubleshooting

#### Module Not Loading

If the module doesn't load automatically:

```bash
# Manually load the module
sudo modprobe aic8800_fdrv

# Check for errors
sudo dmesg | tail -50
```

#### Rebuild After Kernel Update

The driver is automatically rebuilt when you update your kernel through NixOS. Simply run:

```bash
sudo nixos-rebuild switch
```

#### Firmware Issues

If you see firmware-related errors in `dmesg`, ensure your configuration includes:

```nix
hardware.firmware = [ aic8800-driver ];
```

#### USB Device Not Recognized

Check if your device is detected:

```bash
lsusb | grep -E "(3020|368b)"
```

If the device is not listed, try a different USB port or cable.

### Uninstallation

To remove the driver from NixOS:

1. **Disable in configuration:**

   ```nix
   {
     hardware.aic8800.enable = false;
     # or simply remove the line
   }
   ```

2. **Rebuild:**

   ```bash
   sudo nixos-rebuild switch
   ```

The driver and firmware will be automatically removed during garbage collection:

```bash
sudo nix-collect-garbage -d
```

## Known Limitations

- Bluetooth functionality is not supported
- The driver is built specifically for your current kernel version
- Some features may require additional configuration depending on your networking setup

## Disclaimer

I did not develop this software. The code is sourced from the Tenda U11 driver. I only made modifications to adapt it to newer kernel versions and added NixOS support. Apart from compilation issues, I am unable to address other problems.

## Support

For issues specific to NixOS, please open an issue on GitHub with:
- Your NixOS version (`nixos-version`)
- Your kernel version (`uname -r`)
- Output of `dmesg | grep aic8800`
- Your relevant NixOS configuration

For general driver issues, refer to the [original repository](https://github.com/kurumeii/aic8800-nix).
