# Host-specific configuration for redpill-x1-yoga
{ config, pkgs, ... }:

{
  # Import hardware configuration
  imports = [ ./hardware-configuration.nix ];

  # Hostname
  networking.hostName = "redpill-x1-yoga";

  # LUKS encryption setup for this machine
  boot.initrd.luks.devices."cryptroot" = {
    device = "/dev/disk/by-uuid/1fe239ed-81f2-4c97-80cc-30c24ffe8e2f"; # Laptop LUKS UUID
    preLVM = true;
    allowDiscards = true; # Improves SSD performance
  };

  # Any other machine-specific settings can go here
  # For example, if this laptop has specific power management needs:
  # services.tlp.settings = {
  #   CPU_SCALING_GOVERNOR_ON_AC = "performance";
  #   CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
  # };
}
