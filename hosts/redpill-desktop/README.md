# Desktop Configuration (redpill-desktop)

This host configuration is for a desktop system with an Nvidia GPU, optimized for GPU-accelerated workloads including password cracking, AI inference, and transcription.

## Hardware Requirements

- **GPU**: Nvidia GPU (configured for proprietary drivers)
- **CUDA**: Requires CUDA-capable GPU
- **RAM**: Recommended 16GB+ for LLM inference
- **Storage**: Encrypted Btrfs with LUKS (like laptop configuration)

## GPU-Specific Features

### Nvidia Drivers
- Proprietary Nvidia drivers configured in `configuration.nix:15`
- Hardware acceleration enabled with 32-bit support
- Nvidia Settings menu available
- Using stable driver version (can be changed to `beta` or specific version)

### CUDA Support
- CUDA Toolkit installed system-wide
- `cudaSupport` enabled globally for package builds
- Nvidia Container Toolkit enabled for Docker GPU workloads

### Installed GPU Applications

1. **Hashcat** - Password recovery and cracking tool
   - Built with CUDA support
   - Command: `hashcat`

2. **Ollama** - Local LLM inference
   - Running as systemd service with CUDA acceleration
   - Service managed by NixOS: `systemctl status ollama`
   - Access at `http://localhost:11434`
   - Pull models: `ollama pull llama2`
   - Run models: `ollama run llama2`

3. **Faster-Whisper** - Optimized Whisper transcription with CTranslate2
   - Uses CTranslate2 inference engine (much faster than PyTorch)
   - Python environment provided for installation
   - Install faster-whisper: `pip install --user faster-whisper`
   - CTranslate2 with CUDA support is automatically downloaded from PyPI

### Additional Tools
- **cuDNN** - Deep learning library for neural networks
- **NVTOP** - GPU monitoring (like htop for GPUs)
  - Command: `nvtop`

## Initial Setup on Desktop

When setting up this configuration on your desktop for the first time:

1. **Boot from NixOS installation media**

2. **Clone this repository** (if not already done):
   ```bash
   cd /mnt/home
   git clone https://github.com/Natho86/NixOS.git
   cd NixOS
   ```

3. **Generate hardware configuration**:
   ```bash
   nixos-generate-config --root /mnt
   cp /mnt/etc/nixos/hardware-configuration.nix ./hosts/redpill-desktop/
   ```

4. **Get your LUKS UUID and update configuration**:
   ```bash
   # Get the UUID of your encrypted partition
   blkid /dev/sdb2  # Replace with your actual encrypted partition

   # Edit the desktop configuration and replace YOUR-DESKTOP-LUKS-UUID-HERE
   nano hosts/redpill-desktop/configuration.nix
   # Update line 18 with your actual LUKS UUID
   ```

5. **Install the system**:
   ```bash
   nixos-install --flake .#desktop
   ```

5. **Reboot and verify GPU**:
   ```bash
   # Check Nvidia driver is loaded
   nvidia-smi

   # Monitor GPU in real-time
   nvtop

   # Verify CUDA is working
   nvidia-smi --query-gpu=compute_cap --format=csv
   ```

## Building from Laptop

You can build the desktop configuration from your laptop to test for errors:

```bash
# Check for syntax errors without building
nix flake check

# Build the desktop configuration (won't install)
nix build .#nixosConfigurations.desktop.config.system.build.toplevel

# Evaluate the configuration
nix eval .#nixosConfigurations.desktop.config.system.build.toplevel
```

## Usage

### Building on Desktop

```bash
# Rebuild system after configuration changes
sudo nixos-rebuild switch --flake .#desktop

# Or test without switching
sudo nixos-rebuild test --flake .#desktop
```

### Using Ollama

```bash
# Check service status
systemctl status ollama

# Pull a model
ollama pull llama2

# Run a model
ollama run llama2

# List installed models
ollama list

# Remove a model
ollama rm llama2
```

### Using Faster-Whisper

```bash
# Install in user environment (one-time)
pip install --user faster-whisper

# Example usage in Python
python3 << EOF
from faster_whisper import WhisperModel

model = WhisperModel("base", device="cuda", compute_type="float16")
segments, info = model.transcribe("audio.mp3")

for segment in segments:
    print(f"[{segment.start:.2f}s -> {segment.end:.2f}s] {segment.text}")
EOF
```

### Using Hashcat

```bash
# Example: Benchmark GPU performance
hashcat -b

# Example: Crack MD5 hashes
hashcat -m 0 -a 0 hashes.txt wordlist.txt

# Enable optimized kernel (CUDA)
hashcat -O -m 0 -a 0 hashes.txt wordlist.txt
```

## Troubleshooting

### GPU Not Detected
```bash
# Check if driver is loaded
lsmod | grep nvidia

# Check Nvidia SMI
nvidia-smi

# Rebuild with verbose output
sudo nixos-rebuild switch --flake .#desktop --show-trace
```

### CUDA Not Working
```bash
# Verify CUDA installation
nvcc --version

# Check CUDA device
nvidia-smi --query-gpu=compute_cap --format=csv
```

### Ollama Not Starting
```bash
# Check logs
journalctl -u ollama -f

# Restart service
sudo systemctl restart ollama

# Check if port is in use
ss -tlnp | grep 11434
```

### Display Issues
If you experience display problems, try adjusting the Nvidia settings in `configuration.nix:31-43`:
- Set `open = true` for open-source drivers (newer GPUs)
- Change `package` to `legacy_470` for older GPUs
- Disable `powerManagement` if experiencing crashes

## Configuration Files

- `configuration.nix` - Nvidia drivers, hardware acceleration, hostname
- `gpu-packages.nix` - CUDA toolkit and GPU-accelerated applications
- `hardware-configuration.nix` - Auto-generated, machine-specific (not in git)

## Notes

- This configuration shares most settings with the laptop (`shared/configuration.nix` and `shared/home.nix`)
- Only GPU-specific packages and drivers are unique to this host
- Hardware configuration must be generated on the desktop machine
- Unfree packages are allowed for Nvidia drivers (configured in shared config)
