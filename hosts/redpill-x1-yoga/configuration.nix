# Host-specific configuration for redpill-x1-yoga
{ config, pkgs, ... }:

{
  # Import hardware configuration
  imports = [ ./hardware-configuration.nix ];

  # Hostname
  networking.hostName = "redpill-x1-yoga";
  
  # Any other machine-specific settings can go here
  # For example, if this laptop has specific power management needs:
  # services.tlp.settings = {
  #   CPU_SCALING_GOVERNOR_ON_AC = "performance";
  #   CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
  # };
}
