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

  # sops-nix age key location for this host
  sops.age.keyFile = "/home/nath/.config/sops/age/keys.txt";

  # Auto-login after disk unlock (laptop-specific for convenience)
  services.displayManager.autoLogin = {
    enable = true;
    user = "nath";
  };

  # Workaround for auto-login with SDDM
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  # Power management for laptop (TLP)
  services.power-profiles-daemon.enable = false; # Conflicts with TLP
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

      START_CHARGE_THRESH_BAT0 = 40;
      STOP_CHARGE_THRESH_BAT0 = 80;
    };
  };
  # SSH server configuration
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;  # Set to false after setting up SSH keys
      X11Forwarding = false;
    };
  };




}
