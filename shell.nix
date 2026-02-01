# Nix development shell for building and testing the AIC8800 driver
{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  name = "aic8800-dev-shell";

  buildInputs = with pkgs; [
    # Build essentials
    gnumake
    gcc
    
    # Kernel headers
    linuxPackages.kernel.dev
    
    # Utilities
    kmod
    usbutils
    pciutils
    
    # Nix tools
    nixpkgs-fmt
    nix-tree
  ];

  shellHook = ''
    echo "AIC8800D80 Driver Development Shell"
    echo "===================================="
    echo ""
    echo "Kernel version: ${pkgs.linuxPackages.kernel.version}"
    echo ""
    echo "Available commands:"
    echo "  - Build driver: cd drivers/aic8800 && make"
    echo "  - Build Nix package: nix-build"
    echo "  - Build with flakes: nix build"
    echo ""
    echo "Kernel headers: ${pkgs.linuxPackages.kernel.dev}/lib/modules/${pkgs.linuxPackages.kernel.modDirVersion}/build"
    echo ""
  '';
}
