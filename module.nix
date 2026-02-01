# AIC8800D80 NixOS Module Configuration
#
# This file provides a standalone NixOS module for the AIC8800D80 WiFi driver.
# You can import this directly into your NixOS configuration.

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardware.aic8800;
  
  aic8800-driver = config.boot.kernelPackages.callPackage ./default.nix { };

in {
  options.hardware.aic8800 = {
    enable = mkEnableOption "AIC8800D80 WiFi 6 driver support";

    package = mkOption {
      type = types.package;
      default = aic8800-driver;
      defaultText = literalExpression "config.boot.kernelPackages.callPackage ./default.nix { }";
      description = ''
        The AIC8800 driver package to use. By default, it will be built for your
        current kernel version.
      '';
    };

    autoload = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to automatically load the aic8800_fdrv kernel module at boot.
        If set to false, you'll need to manually load it with `modprobe aic8800_fdrv`.
      '';
    };
  };

  config = mkIf cfg.enable {
    # Add the driver to kernel modules
    boot.extraModulePackages = [ cfg.package ];
    
    # Automatically load the module if enabled
    boot.kernelModules = mkIf cfg.autoload [ "aic8800_fdrv" ];
    
    # Install firmware files
    hardware.firmware = [ cfg.package ];

    # Add udev rules for the USB devices
    services.udev.extraRules = ''
      # AIC8800D80 WiFi adapter - Original vendor ID
      ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="3020", ATTRS{idProduct}=="*", MODE="0664", GROUP="users", TAG+="uaccess"
      
      # AIC8800D80 WiFi adapter - Alternative vendor ID (368B - tested)
      ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="368b", ATTRS{idProduct}=="*", MODE="0664", GROUP="users", TAG+="uaccess"
    '';

    # Optional: Add a systemd service to reload the module after suspend/resume
    systemd.services.aic8800-resume = {
      description = "Reload AIC8800 driver after resume";
      after = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
      wantedBy = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.kmod}/bin/modprobe -r aic8800_fdrv || true";
        ExecStartPost = "${pkgs.kmod}/bin/modprobe aic8800_fdrv";
      };
    };
  };

  meta = {
    maintainers = [ ];
    doc = ./README-NIXOS.md;
  };
}
