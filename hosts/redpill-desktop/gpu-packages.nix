# GPU-specific packages for redpill-desktop
{ config, pkgs, ... }:

let
  # Helper to bootstrap a GPU-enabled virtualenv for faster-whisper.
  # Pins ctranslate2 to 4.4.0 to stay on CUDA 12 + cuDNN 8 per upstream guidance:
  # https://github.com/SYSTRAN/faster-whisper?tab=readme-ov-file#gpu
  fasterWhisperVenv = pkgs.writeShellScriptBin "setup-faster-whisper" ''
    set -euo pipefail

    VENV_PATH="${XDG_DATA_HOME:-$HOME/.local/share}/venvs/faster-whisper"
    echo "Creating/refreshing virtualenv at $VENV_PATH"

    python3 -m venv "$VENV_PATH"
    # shellcheck source=/dev/null
    source "$VENV_PATH/bin/activate"

    pip install --upgrade pip
    pip install --force-reinstall "ctranslate2==4.4.0" faster-whisper

    echo "GPU-ready faster-whisper environment is set up."
    echo "Activate with: source $VENV_PATH/bin/activate"
  '';
in {
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

    # CUDA runtime + cuDNN for GPU workloads (e.g., faster-whisper)
    cudaPackages.cudatoolkit
    cudaPackages.cudnn

    # Helper to create a CUDA/ct2-compatible faster-whisper environment
    fasterWhisperVenv

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
