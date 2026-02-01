{ lib
, stdenv
, kernel
, fetchFromGitHub
, kmod
}:

stdenv.mkDerivation rec {
  pname = "aic8800-driver";
  version = "1.0.0";

  src = ./.;

  hardeningDisable = [ "pic" "format" ];
  nativeBuildInputs = kernel.moduleBuildDependencies;

  makeFlags = kernel.makeFlags ++ [
    "KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    "INSTALL_MOD_PATH=$(out)"
  ];

  buildPhase = ''
    runHook preBuild
    
    cd drivers/aic8800
    
    # Build using the kernel build system with proper KDIR
    make -j$NIX_BUILD_CORES \
      KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build \
      ARCH=${stdenv.hostPlatform.linuxArch} \
      modules
    
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    
    mkdir -p $out/lib/modules/${kernel.modDirVersion}/kernel/drivers/net/wireless/aic8800
    cp aic_load_fw/aic_load_fw.ko $out/lib/modules/${kernel.modDirVersion}/kernel/drivers/net/wireless/aic8800/
    cp aic8800_fdrv/aic8800_fdrv.ko $out/lib/modules/${kernel.modDirVersion}/kernel/drivers/net/wireless/aic8800/
    
    # Install firmware
    mkdir -p $out/lib/firmware
    cp -r ../../fw/aic8800D80 $out/lib/firmware/
    
    runHook postInstall
  '';

  meta = with lib; {
    description = "Linux kernel driver for AIC8800D80 WiFi 6 chipset";
    longDescription = ''
      This driver supports the AIC8800D80 chipset, used in devices such as
      the Tenda U11 and AX913B USB WiFi adapters. It provides WiFi 6
      functionality for NixOS systems.
      
      Note: Bluetooth functionality is not supported.
    '';
    homepage = "https://github.com/kurumeii/aic8800-nix";
    license = licenses.gpl2Only;
    platforms = platforms.linux;
    maintainers = [ ];
  };
}
