# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

**Note:** Project-specific instructions for using MCP servers (NixOS and Context7) are in `.claude/instructions.md` and are automatically loaded by Claude Code.

## Repository Overview

This is a NixOS flake-based configuration repository for a laptop running KDE Plasma 6 and Qtile window manager. The configuration uses:
- **Flakes** for reproducible, declarative system configuration
- **Home Manager** for user-level package and configuration management
- **sops-nix** for secrets management
- **Btrfs** with LUKS encryption and compression

## Architecture

### Module Structure

The configuration follows a host + shared pattern:

- `flake.nix` - Flake entry point, defines inputs (nixpkgs, home-manager, sops-nix) and outputs (nixosConfigurations)
- `hosts/redpill-x1-yoga/` - Host-specific configuration
  - `configuration.nix` - Machine-specific settings (hostname, hardware imports)
  - `hardware-configuration.nix` - Auto-generated hardware config (gitignored, machine-specific)
- `shared/` - Shared configuration across all potential hosts
  - `configuration.nix` - System-level config (boot, networking, users, services)
  - `home.nix` - User-level packages and dotfiles (Home Manager)
  - `qtile-config.py` - Qtile window manager configuration

The flake composition in `flake.nix:18-41` combines host-specific config, shared config, and modules (sops-nix, home-manager) into the final system configuration.

### User Configuration

Username: `nath` (defined in `shared/configuration.nix:87-92`)
- Member of groups: networkmanager, wheel, video, audio, docker
- Shell: zsh
- Home directory managed by Home Manager

## Common Development Commands

### System Management

```bash
# Rebuild system after configuration changes
sudo nixos-rebuild switch --flake .#laptop
# OR use Makefile shortcut
make rebuild

# Test configuration without switching (useful for testing changes)
sudo nixos-rebuild test --flake .#laptop
# OR
make test

# Check flake for errors without building
nix flake check
# OR
make check

# Update all flake inputs (nixpkgs, home-manager, etc.)
nix flake update
sudo nixos-rebuild switch --flake .#laptop
# OR
make update
```

### Garbage Collection & Optimization

```bash
# Remove generations older than 7 days
sudo nix-collect-garbage --delete-older-than 7d
# OR
make clean

# Remove ALL old generations except current
sudo nix-collect-garbage -d
# OR
make clean-all

# Optimize nix store (deduplicate identical files)
nix-store --optimise
# OR
make optimize

# List all system generations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system
# OR
make list-generations
```

### Development Workflow

```bash
# Build VM for testing (safer than testing on live system)
nixos-rebuild build-vm --flake .#laptop
./result/bin/run-laptop-vm
# OR
make vm

# Build and set as boot default (takes effect on next boot, not immediately)
sudo nixos-rebuild boot --flake .#laptop
# OR
make boot
```

## Flake Structure

The flake defines a single NixOS configuration with an alias:
- `nixosConfigurations.redpill-x1-yoga` - Primary laptop configuration
- `nixosConfigurations.laptop` - Alias to redpill-x1-yoga (for convenience)

Always use `.#laptop` when rebuilding to reference the current machine configuration.

## Adding Packages

### System-level packages
Edit `shared/configuration.nix:109-136` and add to `environment.systemPackages`.

### User-level packages
Edit `shared/home.nix:14-75` and add to `home.packages`. This is preferred for most applications.

After editing either file, run `sudo nixos-rebuild switch --flake .#laptop` or `make rebuild`.

## Configuration Files

### Neovim
Fully configured with LSP, Treesitter, Telescope, and Catppuccin theme. Configuration is in `shared/home.nix:144-279` as inline Lua.

### Zsh
Configured with oh-my-zsh, starship prompt, syntax highlighting, and auto-suggestions. Shell aliases defined in `shared/home.nix:321-338`:
- `rebuild` - Rebuild system
- `update` - Update flake and rebuild
- `clean` - Garbage collect old generations
- Standard git shortcuts (gs, ga, gc, gp, gl)

### Alacritty Terminal
Configured with Catppuccin Mocha theme in `shared/home.nix:78-142`.

### Qtile Window Manager
Configuration in `shared/qtile-config.py`. Key bindings use Super (mod4) key:
- `Super+Enter` - Launch terminal
- `Super+b` - Launch browser
- `Super+w` - Close window
- `Super+r` - Rofi launcher
- `Super+h/j/k/l` - Navigate windows (vim-style)

## Important System Features

### Disk Encryption
- LUKS encryption configured in `shared/configuration.nix:17-21`
- UUID at line 18 is machine-specific
- Auto-login enabled after disk unlock (`shared/configuration.nix:61-68`)

### Power Management
- TLP configured for battery threshold (40-80%) in `shared/configuration.nix:163-175`
- Conflicts with power-profiles-daemon (disabled at line 162)

### Docker
Enabled system-wide. Users must be in the `docker` group (already configured for user `nath`).

### Tailscale VPN
Enabled in `shared/configuration.nix:28`. Firewall configured to allow Tailscale traffic (lines 195-198).

### Secrets Management
sops-nix configured in `shared/configuration.nix:152-156`. Age key expected at `/home/nath/.config/sops/age/keys.txt`. Secrets file would be at `./secrets/secrets.yaml` (not currently present).

### Flox Package Manager
Trusted substituters configured in `shared/configuration.nix:98-106`. Flox must be installed to user profile separately (see comments in file).

## Git Configuration

Git settings in `shared/home.nix:282-292`:
- Default branch: main
- Auto setup remote on push
- Rebase on pull
- Delta diff viewer enabled with syntax highlighting

## File Locations

When editing configuration:
- System packages & services → `shared/configuration.nix`
- User packages & dotfiles → `shared/home.nix`
- Machine-specific settings → `hosts/redpill-x1-yoga/configuration.nix`
- Qtile config → `shared/qtile-config.py`

## Testing Changes

Always test configuration changes before committing:
1. Run `make test` or `sudo nixos-rebuild test --flake .#laptop` to test without switching
2. If successful, run `make rebuild` to apply permanently
3. If something breaks, reboot and select an older generation from GRUB

## Flake Inputs

Current inputs (defined in `flake.nix:4-16`):
- `nixpkgs` - nixos-unstable channel
- `home-manager` - Following nixpkgs
- `sops-nix` - Following nixpkgs

To update a specific input:
```bash
nix flake lock --update-input nixpkgs
```

## Notes

- `hardware-configuration.nix` is gitignored and machine-specific (must be generated per host)
- Automatic garbage collection runs weekly, deleting generations older than 7 days (`shared/configuration.nix:185-189`)
- Store optimization runs automatically (`shared/configuration.nix:192`)
- Unfree packages are allowed (`shared/configuration.nix:95`) for Chrome, 1Password, Obsidian, Spotify
- System state version: 24.05 (do not change on existing installations)
