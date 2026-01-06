# GPU-specific packages for redpill-desktop
{ config, pkgs, ... }:

{
  # System packages that require or benefit from GPU acceleration
  environment.systemPackages = with pkgs; [
    # Hashcat - Password cracking tool with GPU support
    hashcat

    # Ollama - Local LLM inference with GPU acceleration
    # Ollama in NixOS automatically detects and uses GPU when available
    # NOTE: Currently commented out due to build issues during initial install
    # Uncomment after successful system installation and rebuild
    #ollama

    # NVTOP - GPU monitoring tool (like htop for Nvidia GPUs)
    nvtopPackages.nvidia

    # Python environment for general development
    (python3.withPackages (ps: with ps; [
      # Core dependencies
      pip
      setuptools
      wheel
    ]))
  ];

  # Ollama service configuration
  # This runs Ollama as a system service with GPU acceleration
  # NOTE: Uncomment along with the ollama package above after successful installation
  #services.ollama = {
  #  enable = true;
  #  acceleration = "rocm";  # Enable ROCm acceleration for Ollama (Nvidia also supported)
  #};
}
