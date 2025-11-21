.PHONY: help rebuild update clean test check format

help: ## Show this help message
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

rebuild: ## Rebuild and switch to new configuration
	sudo nixos-rebuild switch --flake .#laptop

test: ## Build configuration and test without switching
	sudo nixos-rebuild test --flake .#laptop

check: ## Check flake for errors without building
	nix flake check

update: ## Update flake inputs and rebuild
	nix flake update
	sudo nixos-rebuild switch --flake .#laptop

clean: ## Remove old generations (older than 7 days)
	sudo nix-collect-garbage --delete-older-than 7d

clean-all: ## Remove ALL old generations except current
	sudo nix-collect-garbage -d

format: ## Format Nix files with nixpkgs-fmt
	nixpkgs-fmt *.nix

optimize: ## Optimize nix store
	nix-store --optimise

list-generations: ## List all system generations
	sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

vm: ## Build a VM for testing
	nixos-rebuild build-vm --flake .#laptop
	./result/bin/run-laptop-vm

boot: ## Build configuration and set as boot default (doesn't switch immediately)
	sudo nixos-rebuild boot --flake .#laptop
