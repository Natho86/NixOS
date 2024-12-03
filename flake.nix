{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
		home-manager.url = "github:nix-community/home-manager/master";
		home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

	outputs = { self, nixpkgs, home-manager, ...}:
		let
			lib = nixpkgs.lib;
			system = "x86_64-linux";
			pkgs = nixpkgs.legacyPackages.${system};
		in {
			nixosConfigurations = {
				redpill-nix-yoga = lib.nixosSystem {
					inherit system;
					modules = [ ./configuration.nix ];
				};
			};
			homeConfigurations = {
				nath = home-manager.lib.homeManagerConfiguration {
				inherit pkgs;
				modules = [ ./home.nix ];
				};
			};
		};
}

