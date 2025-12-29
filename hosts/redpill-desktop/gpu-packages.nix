# GPU-specific packages for redpill-desktop
{ config, pkgs, ... }:

{
  # System packages that require or benefit from GPU acceleration
  environment.systemPackages = with pkgs; [
    # CUDA Toolkit 12.x - Essential for GPU development and acceleration
    # Using CUDA 12 specifically as required by faster-whisper and ctranslate2
    cudaPackages_12.cudatoolkit

    # cuDNN - CUDA Deep Neural Network library (useful for ML workloads)
    cudaPackages_12.cudnn

    # Hashcat - Password cracking tool with CUDA support
    # Note: NixOS hashcat is built with CUDA support by default when cudaSupport is enabled
    hashcat

    # Ollama - Local LLM inference with GPU acceleration
    # Ollama in NixOS automatically detects and uses CUDA when available
    # NOTE: Currently commented out due to build issues during initial install
    # Uncomment after successful system installation and rebuild
    #ollama

    # NVTOP - GPU monitoring tool (like htop for Nvidia GPUs)
    nvtopPackages.nvidia

    # Python environment with faster-whisper and CUDA support
    # faster-whisper uses CTranslate2 for optimized inference (much faster than PyTorch)
    (python3.withPackages (ps: with ps; [
      # Core dependencies
      pip
      setuptools
      wheel

      # faster-whisper and its dependencies
      # CTranslate2 is the optimized inference engine used by faster-whisper
      # Note: Install faster-whisper via pip to get CUDA-enabled CTranslate2:
      #   pip install --user faster-whisper
      #
      # The package will automatically use CUDA when available
      # CTranslate2 binaries with CUDA support will be fetched from PyPI
    ]))
  ];

  # Ollama service configuration
  # This runs Ollama as a system service with GPU acceleration
  # NOTE: Uncomment along with the ollama package above after successful installation
  #services.ollama = {
  #  enable = true;
  #  acceleration = "cuda";  # Enable CUDA acceleration for Ollama
  #  # Uncomment and modify if you want to specify GPU devices:
  #  # environmentVariables = {
  #  #   CUDA_VISIBLE_DEVICES = "0";
  #  # };
  #};
}
