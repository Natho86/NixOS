# Repository Guidelines

## Project Structure & Module Organization
- `flake.nix` defines inputs and the NixOS outputs. Host-specific entry points live under `hosts/`.
- `hosts/redpill-x1-yoga/` and `hosts/redpill-desktop/` contain per-machine `configuration.nix` plus optional helpers (e.g., `gpu-packages.nix`).
- `shared/` contains common modules: `configuration.nix` for system settings, `home.nix` for Home Manager, and `qtile-config.py` for Qtile.
- Secrets are managed via sops-nix; the example file is `secrets.yaml.example`, and real secrets live under `secrets/` (gitignored).

## Build, Test, and Development Commands
- `make rebuild`: rebuild and switch to the current host (defaults to `.#laptop`).
- `make test`: build and test without switching; safer for changes.
- `make check`: run `nix flake check` for basic validation.
- `make update`: update flake inputs and rebuild.
- `make format`: format Nix files with `nixpkgs-fmt`.
- Equivalent direct commands include `sudo nixos-rebuild switch --flake .#laptop` and `sudo nixos-rebuild test --flake .#laptop`.

## Coding Style & Naming Conventions
- Nix files follow two-space indentation and conventional module style (`{ config, pkgs, ... }:` then an attribute set).
- Use `nixpkgs-fmt` via `make format` when touching `.nix` files.
- Keep host-specific changes in `hosts/<host>/configuration.nix`; keep shared settings in `shared/`.

## Testing Guidelines
- There is no dedicated test suite. Use `make test` to validate system builds and `make check` for flake checks.
- Prefer `nixos-rebuild test` before `switch` to avoid breaking the running system.

## Commit & Pull Request Guidelines
- Commits are short, imperative, and descriptive (e.g., “Add GPU-ready faster-whisper tooling”).
- PRs should describe the host impacted, summarize the Nix modules touched, and include relevant commands run (e.g., `make test`).
- If a change introduces secrets or host-specific data, verify it stays out of git (hardware configs and `secrets/` are ignored).

## Security & Configuration Tips
- `hardware-configuration.nix` is machine-specific and should not be committed.
- Update LUKS UUIDs only in the relevant host config under `hosts/`.
- Keep age keys under `~/.config/sops/age/` and use `secrets.yaml.example` as a template.

## Agent Notes
- If you are an automation agent, read `CLAUDE.md` for repository-specific context and workflows.
