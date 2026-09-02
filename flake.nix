{
  description = "NixOS configurations with Plasma 6, Qtile, and AI server";

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

          # Omarchy-inspired Hyprland desktop (additive; see omarchy-inspired-nixos-plan.md)
          ./shared/desktop/omarchy

          # Modules
          sops-nix.nixosModules.sops
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.nath = {
              imports = [
                ./shared/home.nix
                ./shared/desktop/omarchy/home.nix
                ./shared/desktop/omarchy/lock-idle.nix
                ./shared/desktop/omarchy/screenshot.nix
                ./shared/desktop/omarchy/wallpaper.nix
                ./shared/desktop/omarchy/clipboard.nix
                ./shared/desktop/omarchy/night-light.nix
                ./shared/desktop/omarchy/osd-helpers.nix
                ./shared/desktop/omarchy/applications.nix
                ./shared/desktop/omarchy/window-rules.nix
                ./shared/desktop/omarchy/launcher.nix
                ./shared/desktop/omarchy/power-menu.nix
                ./shared/desktop/omarchy/shell-tools.nix
                ./shared/desktop/omarchy/gtk-theme.nix
                ./shared/desktop/omarchy/theme-switch.nix
              ];
            };
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

      # AI server configuration with NVIDIA GPU acceleration
      nixosConfigurations.ai-server = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          # Host-specific server configuration
          ./hosts/ai-server/configuration.nix
        ];
      };

      # Easy aliases for your machines
      nixosConfigurations.laptop = self.nixosConfigurations.redpill-x1-yoga;
      nixosConfigurations.desktop = self.nixosConfigurations.redpill-desktop;
      nixosConfigurations.server = self.nixosConfigurations.ai-server;

    };
}
