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

  # Ollama service configuration
  # This runs Ollama as a system service with GPU acceleration
  # NOTE: Uncomment along with the ollama package above after successful installation
  #services.ollama = {
  #  enable = true;
  #  acceleration = "rocm";  # Enable ROCm acceleration for Ollama (Nvidia also supported)
  #};
}
