# GPU-specific packages for redpill-desktop
{ config, pkgs, ... }:

{
  # System packages that require or benefit from GPU acceleration
  environment.systemPackages = with pkgs; [
    # Hashcat - Password cracking tool with GPU support
    hashcat

    # NVTOP - GPU monitoring tool (like htop for Nvidia GPUs)
    nvtopPackages.nvidia
  ];
}
