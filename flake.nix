{
  description = "NixOS configuration with Plasma 6 and Qtile";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, sops-nix, ... }@inputs:
    let
      systems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in {
      # Laptop configuration
      nixosConfigurations.redpill-x1-yoga = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          # Host-specific configuration
          ./hosts/redpill-x1-yoga/configuration.nix

          # Shared configuration
          ./shared/configuration.nix

          # Modules
          sops-nix.nixosModules.sops
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.nath = import ./shared/home.nix;
            home-manager.extraSpecialArgs = { inherit inputs; };
          }
        ];
      };

      # Desktop configuration with Nvidia GPU
      nixosConfigurations.redpill-desktop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          # Host-specific configuration (includes Nvidia drivers and GPU packages)
          ./hosts/redpill-desktop/configuration.nix

          # Shared configuration
          ./shared/configuration.nix

          # Modules
          sops-nix.nixosModules.sops
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.nath = import ./shared/home.nix;
            home-manager.extraSpecialArgs = { inherit inputs; };
          }
        ];
      };

      # Easy aliases for your machines
      nixosConfigurations.laptop = self.nixosConfigurations.redpill-x1-yoga;
      nixosConfigurations.desktop = self.nixosConfigurations.redpill-desktop;

      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };

          cudaLibs = with pkgs.cudaPackages; [
            cuda_cudart
            cudnn
            libcublas
          ];

          baseLibs = [
            pkgs.stdenv.cc.cc.lib
            pkgs.zlib
            pkgs.ffmpeg
          ];
        in {
          default = pkgs.mkShell {
            packages = [
              (pkgs.python311.withPackages (ps: with ps; [
                pip
                setuptools
                wheel
              ]))
              pkgs.ffmpeg
              pkgs.zlib
            ] ++ cudaLibs;

            shellHook = ''
              export CUDA_HOME=${pkgs.cudaPackages.cuda_cudart}
              export LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath (cudaLibs ++ baseLibs)}:''${LD_LIBRARY_PATH:-}
              export CT2_FORCE_CPU=0

              echo "CUDA-enabled dev shell ready."
              echo "LD_LIBRARY_PATH is set so ctranslate2 GPU wheels can find libcudart, cuDNN, and cuBLAS."
            '';
          };
        });
    };
}
