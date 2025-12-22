{
  description = "NixOS configuration with managed WiFi driver";

  inputs = {
    # Use the version of NixOS you are currently on (unstable or 24.11 etc)
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # The WiFi driver source - the flake.lock will manage the hash for you
    rtl8852cu-src = {
      url = "github:morrownr/rtl8852cu-20240510";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, rtl8852cu-src, ... }@inputs: {
    # Replace 'nixos' with your actual hostname if it's different
    nixosConfigurations.dqb = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./configuration.nix
        
        # This module handles the driver using the flake input
        ({ config, pkgs, lib, ... }: {
          boot.extraModulePackages = [
            (config.boot.kernelPackages.callPackage ({ stdenv, kernel, bc }:
              stdenv.mkDerivation rec {
                pname = "rtl8852cu";
                version = "20240510";

                # This pulls directly from the flake input defined above
                src = rtl8852cu-src;

                nativeBuildInputs = [ kernel.moduleBuildDependencies bc ];

                postPatch = ''
                  find . -type f -exec sed -i 's/hmac_sha256/rtw_hmac_sha256/g' {} +
                '';

                makeFlags = [
                  "ARCH=${stdenv.hostPlatform.linuxArch}"
                  "KSRC=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
                ];

                enableParallelBuilding = true;

                installPhase = ''
                  mkdir -p $out/lib/modules/${kernel.modDirVersion}/kernel/drivers/net/wireless/realtek/rtl8852cu
                  cp 8852cu.ko $out/lib/modules/${kernel.modDirVersion}/kernel/drivers/net/wireless/realtek/rtl8852cu
                '';
              }) {})
          ];
        })
      ];
    };
  };
}
