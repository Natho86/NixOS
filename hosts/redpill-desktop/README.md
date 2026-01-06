# Desktop Configuration (redpill-desktop)

This host configuration is for a desktop system with an Nvidia GPU, optimized for GPU-accelerated workloads including password cracking and containerized AI inference.

## Hardware Requirements

- **GPU**: Nvidia GPU (configured for proprietary drivers)
- **RAM**: Recommended 16GB+ for LLM inference
- **Storage**: Encrypted Btrfs with LUKS (like laptop configuration)

## GPU-Specific Features

### Nvidia Drivers
- Proprietary Nvidia drivers configured in `configuration.nix:15`
- Hardware acceleration enabled with 32-bit support
- Nvidia Settings menu available
- Using stable driver version (can be changed to `beta` or specific version)

### Installed GPU Applications

1. **Hashcat** - Password recovery and cracking tool
   - Built with GPU support
   - Command: `hashcat`

2. **NVTOP** - GPU monitoring (like htop for GPUs)
   - Command: `nvtop`

### NVIDIA Container Toolkit for Docker
- The NVIDIA Container Toolkit is enabled so Docker containers can access the GPU.
- Rebuild, then restart Docker before running GPU-enabled containers:
  ```bash
  sudo systemctl restart docker
  ```
- Test GPU access in containers after restarting Docker:
  ```bash
  docker run --rm --gpus all nvidia/cuda:12.5.0-base-ubuntu22.04 nvidia-smi
  ```

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

### Using Hashcat

```bash
# Example: Benchmark GPU performance
hashcat -b

# Example: Crack MD5 hashes
hashcat -m 0 -a 0 hashes.txt wordlist.txt

# Enable optimized kernel
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

### Display Issues
If you experience display problems, try adjusting the Nvidia settings in `configuration.nix:31-43`:
- Set `open = true` for open-source drivers (newer GPUs)
- Change `package` to `legacy_470` for older GPUs
- Disable `powerManagement` if experiencing crashes

## Configuration Files

- `configuration.nix` - Nvidia drivers, hardware acceleration, hostname
- `gpu-packages.nix` - GPU-accelerated applications
- `hardware-configuration.nix` - Auto-generated, machine-specific (not in git)

## Migration Notes

- The previous CUDA development shell and faster-whisper virtualenv helper have been removed. GPU workloads should now run inside Docker containers using the NVIDIA Container Toolkit.

## Notes

- This configuration shares most settings with the laptop (`shared/configuration.nix` and `shared/home.nix`)
- Only GPU-specific packages and drivers are unique to this host
- Hardware configuration must be generated on the desktop machine
- Unfree packages are allowed for Nvidia drivers (configured in shared config)
