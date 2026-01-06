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

    };
}
