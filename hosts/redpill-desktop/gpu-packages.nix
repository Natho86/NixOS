# GPU-specific packages for redpill-desktop
{ config, pkgs, ... }:

let
  python = pkgs.python311;
  cudaRuntime = pkgs.cudaPackages.cuda_cudart;
  cudaDnn = pkgs.cudaPackages.cudnn;
  cudaBlas = pkgs.cudaPackages.libcublas;
  # Helper to bootstrap a GPU-enabled virtualenv for faster-whisper.
  # Pins ctranslate2 to 4.4.0 to stay on CUDA 12 + cuDNN 8 per upstream guidance:
  # https://github.com/SYSTRAN/faster-whisper?tab=readme-ov-file#gpu
  fasterWhisperVenv = pkgs.writeShellScriptBin "setup-faster-whisper" ''
    set -euo pipefail

    VENV_PATH="''${XDG_DATA_HOME:-$HOME/.local/share}/venvs/faster-whisper"
    mkdir -p "$(dirname "$VENV_PATH")"

    # If anything fails, warn about a partially created venv so the user can clean it up.
    trap 'echo "setup-faster-whisper failed; the virtualenv may be incomplete" >&2' ERR
    echo "Creating/refreshing virtualenv at $VENV_PATH"

    ${python}/bin/python -m venv "$VENV_PATH"
    # shellcheck source=/dev/null
    source "$VENV_PATH/bin/activate"

    export CUDA_HOME="${cudaRuntime}"
    # Keep the backslash before the LD_LIBRARY_PATH expansion so it is expanded after activation.
    export LD_LIBRARY_PATH="${cudaRuntime}/lib:${cudaDnn}/lib:${cudaBlas}/lib:${pkgs.stdenv.cc.cc.lib}/lib:${pkgs.zlib}/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

    pip install --upgrade pip
    pip install --upgrade "ctranslate2==4.4.0" faster-whisper

    # Ensure the virtualenv activation script exports CUDA paths (python's venv
    # does not load activate.d hooks by default).
    if ! grep -qF "setup-faster-whisper CUDA env" "$VENV_PATH/bin/activate"; then
      cat >>"$VENV_PATH/bin/activate" <<EOF
# setup-faster-whisper CUDA env
export CUDA_HOME="${cudaRuntime}"
export LD_LIBRARY_PATH="${cudaRuntime}/lib:${cudaDnn}/lib:${cudaBlas}/lib:${pkgs.stdenv.cc.cc.lib}/lib:${pkgs.zlib}/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
EOF
    fi

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
    # cudaPackages.cudatoolkit is deprecated; use runtime redist packages instead.
    cudaPackages.cuda_cudart
    cudaPackages.cudnn
    cudaPackages.libcublas

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
