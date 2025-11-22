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

  outputs = { self, nixpkgs, home-manager, sops-nix, ... }@inputs: {
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
          home-manager.backupFileExtension = "backup";
        }
      ];
    };
    
    # Easy alias for your current machine
    nixosConfigurations.laptop = self.nixosConfigurations.redpill-x1-yoga;
  };
}
