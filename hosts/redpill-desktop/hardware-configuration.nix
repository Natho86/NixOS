# PLACEHOLDER - This file must be generated on the desktop machine
# Run: sudo nixos-generate-config --show-hardware-config > hardware-configuration.nix
#
# This placeholder allows the flake to be checked/built from the laptop
# but will NOT work for actual installation until replaced with real hardware config

{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ ];

  # Placeholder boot configuration - REPLACE with actual hardware config
  boot.loader.systemd-boot.enable = lib.mkDefault true;
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;

  # Placeholder filesystem - REPLACE with actual hardware config
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  # Placeholder networking - REPLACE with actual hardware config
  networking.useDHCP = lib.mkDefault true;

  # Placeholder system - REPLACE with actual hardware config
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
