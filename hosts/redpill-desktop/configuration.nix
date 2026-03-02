# Host-specific configuration for redpill-desktop
{ config, lib, pkgs, ... }:

{
  # Import hardware configuration
  imports = [
    ./hardware-configuration.nix
    ./gpu-packages.nix
  ];

  # Hostname
  networking.hostName = "redpill-desktop";

  # sops-nix age key location for this host
  sops.age.keyFile = "/home/nath/.config/sops/age/keys.txt";

  # Disable auto-login on desktop (require login for security)
  services.displayManager.autoLogin.enable = lib.mkForce false;

  # Enable getty services (disabled on laptop for auto-login workaround)
  systemd.services."getty@tty1".enable = lib.mkForce true;
  systemd.services."autovt@tty1".enable = lib.mkForce true;

  # Default to X11 session for better Nvidia compatibility
  services.displayManager.defaultSession = lib.mkForce "plasmax11";

  # Desktop performance tuning
  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
    "vm.vfs_cache_pressure" = 50;
  };

  # CPU Governor - Maximum performance for desktop
  powerManagement.cpuFreqGovernor = "performance";

  # Nvidia GPU Configuration
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.nvidia = {
    modesetting.enable = true;

    # Persistenced helps keep device nodes/driver state stable across session startups
    nvidiaPersistenced = true;

    powerManagement.enable = false;
    powerManagement.finegrained = false;

    # IMPORTANT:
    # The "open" kernel module can be finicky depending on GPU generation + driver combo.
    # For stability (especially with display manager login/session start), default to proprietary.
    open = lib.mkDefault false;

    nvidiaSettings = true;

    # Stable driver
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Enable Nvidia container toolkit (CDI)
  hardware.nvidia-container-toolkit.enable = true;

  # Fix: CDI generator sometimes races udev/NVIDIA device nodes at boot/login.
  # Make it wait briefly for /dev/nvidiactl and run after nvidia-persistenced.
  systemd.services.nvidia-container-toolkit-cdi-generator = {
    after = [
      "nvidia-persistenced.service"
      "systemd-udev-settle.service"
    ];
    requires = [ "nvidia-persistenced.service" ];

    serviceConfig = {
      ExecStartPre = [
        "/bin/sh -lc 'for i in $(seq 1 50); do [ -e /dev/nvidiactl ] && exit 0; sleep 0.1; done; echo /dev/nvidiactl not found; exit 1'"
      ];
      Restart = "on-failure";
      RestartSec = "1s";
    };
  };

  # SSH server configuration
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true; # Set to false after setting up SSH keys
      X11Forwarding = false;
    };
  };
}
