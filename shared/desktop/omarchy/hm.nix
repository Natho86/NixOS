# Milestone 8: Home Manager umbrella for the Omarchy-inspired desktop.
# One entry point for flake.nix to import per host, instead of listing
# every sibling module file there directly -- makes "opt a host into the
# desktop" a single line (this file) rather than a list that has to be
# kept in sync with what shared/desktop/omarchy/ actually contains.
#
# Gated on osConfig.desktop.omarchy.enable (the NixOS-level option
# defined in default.nix) rather than a separate Home Manager-level
# option: osConfig is a real, always-available Home Manager special arg
# when Home Manager runs as a NixOS module (confirmed against the pinned
# source, nixos/common.nix's own hmModule.specialArgs -- `osConfig =
# config;`, unconditional, not something flake.nix has to wire up
# itself), so one option controls both the system-level and user-level
# halves of this desktop rather than needing two options kept in sync.
#
# `imports` is special-cased by the module system and merged before
# option values are resolved, so `imports = lib.mkIf cond [...]` is not
# a valid pattern (confirmed by its absence anywhere in the pinned
# nixpkgs/home-manager source -- not just an assumption) -- gating which
# files even get imported has to happen as a plain Nix `if`, at
# expression-evaluation time, not via mkIf. Every module file listed
# below (home.nix, lock-idle.nix, etc.) still works standalone if
# imported directly, so this list stays empty rather than importing
# files whose top-level bodies were never written to be conditional.
{ osConfig, lib, ... }:

{
  imports = lib.optionals osConfig.desktop.omarchy.enable [
    ./home.nix
    ./lock-idle.nix
    ./screenshot.nix
    ./wallpaper.nix
    ./clipboard.nix
    ./night-light.nix
    ./osd-helpers.nix
    ./applications.nix
    ./window-rules.nix
    ./launcher.nix
    ./power-menu.nix
    ./shell-tools.nix
    ./gtk-theme.nix
  ];
}
