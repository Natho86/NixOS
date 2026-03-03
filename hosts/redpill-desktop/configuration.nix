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

  # Packages (single definition; no duplicates)
  environment.systemPackages = with pkgs; [
    digikam
  ];


  services.displayManager.autoLogin.enable = lib.mkForce false;

  systemd.services."getty@tty1".enable = lib.mkForce true;
  systemd.services."autovt@tty1".enable = lib.mkForce true;

  services.displayManager.defaultSession = lib.mkForce "plasmax11";

  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
    "vm.vfs_cache_pressure" = 50;
  };

  powerManagement.cpuFreqGovernor = "performance";

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.nvidia = {
    modesetting.enable = true;
    nvidiaPersistenced = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = lib.mkDefault false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  hardware.nvidia-container-toolkit.enable = true;

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

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;
      X11Forwarding = false;
    };
  };
}