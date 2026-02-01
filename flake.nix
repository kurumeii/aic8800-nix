{
  description = "Linux kernel driver for AIC8800D80 WiFi 6 chipset";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      # Kernel module package
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.callPackage ./default.nix {
            kernel = pkgs.linuxPackages.kernel;
          };
        }
      );

      # NixOS module
      nixosModules.default = { config, lib, pkgs, ... }:
        with lib;
        let
          cfg = config.hardware.aic8800;
        in
        {
          options.hardware.aic8800 = {
            enable = mkEnableOption "AIC8800D80 WiFi driver";

            package = mkOption {
              type = types.package;
              default = config.boot.kernelPackages.callPackage ./default.nix { };
              defaultText = literalExpression "config.boot.kernelPackages.callPackage ./default.nix { }";
              description = "AIC8800 driver package to use";
            };
          };

          config = mkIf cfg.enable {
            boot.extraModulePackages = [ cfg.package ];
            boot.kernelModules = [ "aic8800_fdrv" ];
            
            # Install firmware
            hardware.firmware = [ cfg.package ];

            # Add udev rules
            services.udev.extraRules = ''
              # AIC8800D80 WiFi adapter rules
              ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="3020", ATTRS{idProduct}=="*", MODE="0664", GROUP="users"
              ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="368b", ATTRS{idProduct}=="*", MODE="0664", GROUP="users"
            '';
          };
        };
    };
}
