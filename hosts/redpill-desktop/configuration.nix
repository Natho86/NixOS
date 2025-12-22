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

  # No disk encryption on desktop

  # sops-nix age key location for this host
  sops.age.keyFile = "/home/nath/.config/sops/age/keys.txt";

  # Disable auto-login on desktop (require login for security)
  services.displayManager.autoLogin.enable = lib.mkForce false;

  # Enable getty services (disabled on laptop for auto-login workaround)
  systemd.services."getty@tty1".enable = lib.mkForce true;
  systemd.services."autovt@tty1".enable = lib.mkForce true;

  # Nvidia GPU Configuration
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;  # Enable 32-bit support for compatibility
  };

  hardware.nvidia = {
    # Modesetting is required for most Wayland compositors
    modesetting.enable = true;

    # Enable power management (can cause issues with some GPUs, disable if problems occur)
    powerManagement.enable = false;

    # Fine-grained power management (turns off GPU when not in use)
    # Experimental, may cause issues
    powerManagement.finegrained = false;

    # Use the open source kernel module (for newer GPUs)
    # Set to false if you have an older GPU or experience issues
    open = false;

    # Enable the Nvidia settings menu
    nvidiaSettings = true;

    # Select the appropriate driver version
    # Use 'latest' for most recent stable, 'beta' for beta drivers, or 'legacy_470' etc. for older GPUs
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # CUDA Support
  # This makes CUDA toolkit available system-wide
  nixpkgs.config.cudaSupport = true;

  # Enable Docker with Nvidia GPU support (useful for containerized GPU workloads)
  hardware.nvidia-container-toolkit.enable = true;

  services.openssh = {
    enable = true;
  };
}
