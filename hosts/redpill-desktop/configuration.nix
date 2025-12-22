# Host-specific configuration for redpill-desktop
{ config, pkgs, ... }:

{
  # Import hardware configuration
  imports = [
    ./hardware-configuration.nix
    ./gpu-packages.nix
  ];

  # Hostname
  networking.hostName = "redpill-desktop";

  # LUKS encryption setup for this machine
  # IMPORTANT: Replace the UUID below with your actual LUKS UUID
  # Get it with: blkid /dev/sdb2 (or your encrypted partition)
  #boot.initrd.luks.devices."cryptroot" = {
  #  device = "/dev/disk/by-uuid/YOUR-DESKTOP-LUKS-UUID-HERE";
  #  preLVM = true;
  #  allowDiscards = true; # Improves SSD performance
  #};

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
