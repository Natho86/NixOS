# NixOS Flake Configuration

Modern NixOS configuration with Plasma 6, Qtile, full disk encryption, and Home Manager.

## What's Included

**Desktop Environments:**
- KDE Plasma 6 (Wayland) - default
- Qtile tiling window manager

**Applications:**
- Google Chrome, 1Password, Audacity, Docker, GitHub Desktop, Obsidian
- Neovim (fully configured with LSP), Spotify, Signal, WhatsApp
- Alacritty terminal with Catppuccin theme

**Features:**
- Full disk encryption (LUKS) with auto-login after unlock
- Btrfs filesystem with compression and subvolumes
- Secrets management with sops-nix
- TLP power management for laptops
- Automatic garbage collection
- Catppuccin theme throughout

## Installation Methods

### Option A: Fresh Installation

**1. Boot NixOS installation media and connect to internet**

**2. Partition and encrypt disk:**
```bash
DISK=/dev/nvme0n1  # Change to your disk (check with lsblk)

# Create partitions
parted $DISK -- mklabel gpt
parted $DISK -- mkpart ESP fat32 1MiB 512MiB
parted $DISK -- set 1 esp on
parted $DISK -- mkpart primary 512MiB 100%

# Setup encryption
cryptsetup luksFormat ${DISK}p2
cryptsetup open ${DISK}p2 cryptroot

# Format boot partition
mkfs.fat -F 32 ${DISK}p1

# Format root with btrfs
mkfs.btrfs /dev/mapper/cryptroot

# Create btrfs subvolumes
mount /dev/mapper/cryptroot /mnt
btrfs subvolume create /mnt/root
btrfs subvolume create /mnt/home
btrfs subvolume create /mnt/nix
umount /mnt

# Mount subvolumes with compression
mount -o subvol=root,compress=zstd,noatime /dev/mapper/cryptroot /mnt
mkdir -p /mnt/{home,nix,boot}
mount -o subvol=home,compress=zstd,noatime /dev/mapper/cryptroot /mnt/home
mount -o subvol=nix,compress=zstd,noatime /dev/mapper/cryptroot /mnt/nix
mount ${DISK}p1 /mnt/boot
```

**3. Clone this configuration:**
```bash
nix-shell -p git
cd /mnt/home
git clone https://github.com/Natho86/NixOS.git
cd NixOS
```

**4. Generate hardware config:**
```bash
nixos-generate-config --root /mnt

# For laptop installation:
cp /mnt/etc/nixos/hardware-configuration.nix ./hosts/redpill-x1-yoga/

# For desktop installation:
cp /mnt/etc/nixos/hardware-configuration.nix ./hosts/redpill-desktop/
```

**5. Customize configuration:**
```bash
# Get your LUKS UUID
blkid ${DISK}p2  # For NVMe: ${DISK}p2, for SATA/SSD: ${DISK}2

# For laptop - edit hosts/redpill-x1-yoga/configuration.nix
# For desktop - edit hosts/redpill-desktop/configuration.nix
# Update the LUKS UUID on line ~18

# Edit shared/home.nix and update:
# - Git name and email (lines ~282-292)
nano shared/home.nix
```

**6. Install:**
```bash
# For laptop:
nixos-install --flake .#laptop

# For desktop:
nixos-install --flake .#desktop

# Set root password when prompted

# Set user password (username is 'nath')
nixos-enter --root /mnt -c "passwd nath"

# Reboot
reboot
```

### Option B: Existing NixOS System

**1. Clone this repository:**
```bash
git clone https://github.com/Natho86/NixOS.git ~/NixOS
cd ~/NixOS
```

**2. Generate your hardware config:**
```bash
# For laptop:
sudo nixos-generate-config --show-hardware-config > hosts/redpill-x1-yoga/hardware-configuration.nix

# For desktop:
sudo nixos-generate-config --show-hardware-config > hosts/redpill-desktop/hardware-configuration.nix
```

**3. Customize configuration:**
```bash
# Get your LUKS UUID (if using encryption)
sudo blkid /dev/nvme0n1p2  # or your encrypted partition (sdb2 for SATA)

# For laptop - edit hosts/redpill-x1-yoga/configuration.nix
# For desktop - edit hosts/redpill-desktop/configuration.nix
# Update the LUKS UUID on line ~18

# Update shared/home.nix:
# - Git name and email (lines ~282-292)
nano shared/home.nix
```

**4. Test and apply:**
```bash
# For laptop - test the configuration
sudo nixos-rebuild test --flake .#laptop

# For desktop - test the configuration
sudo nixos-rebuild test --flake .#desktop

# If everything works, apply it
sudo nixos-rebuild switch --flake .#laptop  # or .#desktop
```

## Post-Installation

### Essential Commands
```bash
# Rebuild system after changes
sudo nixos-rebuild switch --flake ~/NixOS#laptop  # or #desktop

# Update all packages
cd ~/NixOS
nix flake update
sudo nixos-rebuild switch --flake .#laptop  # or #desktop

# Clean old generations
sudo nix-collect-garbage --delete-older-than 7d
```

### Switch Desktop Environments
At the SDDM login screen, click the session selector and choose:
- **Plasma (Wayland)** - KDE Plasma 6
- **Qtile** - Tiling window manager

### Qtile Keybindings
- `Super + Enter` - Terminal
- `Super + r` - App launcher
- `Super + b` - Browser
- `Super + w` - Close window
- `Super + 1-9` - Switch workspace
- `Super + h/j/k/l` - Navigate windows

## Adding Applications

Edit `shared/home.nix` and add to `home.packages`:
```nix
home.packages = with pkgs; [
  google-chrome
  # Add your packages here
  firefox
  vlc
];
```

Then rebuild:
```bash
sudo nixos-rebuild switch --flake ~/NixOS#laptop  # or #desktop
```

## File Structure

```
NixOS/
├── flake.nix                              # Flake definition with all host configurations
├── hosts/                                 # Host-specific configurations
│   ├── redpill-x1-yoga/                  # Laptop
│   │   ├── configuration.nix             # Laptop-specific settings + LUKS UUID
│   │   └── hardware-configuration.nix    # Auto-generated (not in git)
│   └── redpill-desktop/                  # Desktop
│       ├── configuration.nix             # Desktop-specific settings + LUKS UUID + Nvidia
│       ├── gpu-packages.nix              # GPU-specific packages (Ollama, etc.)
│       ├── hardware-configuration.nix    # Auto-generated (not in git)
│       └── README.md                     # Desktop setup guide
├── shared/                                # Shared configuration across all hosts
│   ├── configuration.nix                 # System-level config (services, users, etc.)
│   ├── home.nix                          # User environment (packages, dotfiles)
│   └── qtile-config.py                   # Qtile window manager config
├── .gitignore                            # Protects secrets and hardware configs
├── Makefile                              # Shortcuts for common commands
├── README.md                             # This file
└── secrets/
    └── secrets.yaml                      # Encrypted secrets (not in git)
```

## Secrets Management (Optional)

Setup sops-nix for encrypted secrets:

```bash
# Generate age key
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
age-keygen -y ~/.config/sops/age/keys.txt  # Get public key

# Create .sops.yaml with your public key
cat > ~/NixOS/.sops.yaml << 'EOF'
keys:
  - &admin YOUR_PUBLIC_KEY_HERE
creation_rules:
  - path_regex: secrets/secrets.yaml$
    key_groups:
    - age:
      - *admin
EOF

# Edit secrets (auto-encrypted on save)
cd ~/NixOS
sops secrets/secrets.yaml
```

## Git Safety

The `.gitignore` automatically protects:
- `hardware-configuration.nix` (machine-specific)
- `secrets/secrets.yaml` (actual secrets)
- Age encryption keys
- Build artifacts

Safe to commit:
- All `.nix` files (with placeholders)
- Documentation
- `qtile-config.py`
- `.gitignore`, `Makefile`

## Avoiding PR Conflicts

Keep pull requests small and based on the latest `main` to avoid Codex‑generated PRs clashing with local changes:

1. Sync before starting work:
   ```bash
   git fetch origin
   git rebase origin/main
   ```
2. Create a fresh branch per change (`git switch -c feature/gpu-docs`) and delete it after merging.
3. Avoid stacking multiple unmerged PRs that touch the same files; rebase each branch before asking Codex to propose updates.
4. If a PR is closed without merging, reset your branch to `origin/main` before retrying so Codex starts from a clean state.

## Customization

**Change timezone:**
```nix
# In shared/configuration.nix
time.timeZone = "America/Los_Angeles";
```

**Adjust power management:**
```nix
# In shared/configuration.nix
services.tlp.settings = {
  START_CHARGE_THRESH_BAT0 = 40;
  STOP_CHARGE_THRESH_BAT0 = 80;
};
```

**Change theme:** Edit colors in `shared/home.nix` and `shared/qtile-config.py`

## Multiple Machines

This repository supports multiple hosts (laptop and desktop). Each host has its own directory under `hosts/`:

**Setup process:**
1. Clone the repo on each machine
2. Generate hardware config for that specific host:
   ```bash
   # On laptop:
   sudo nixos-generate-config --show-hardware-config > hosts/redpill-x1-yoga/hardware-configuration.nix

   # On desktop:
   sudo nixos-generate-config --show-hardware-config > hosts/redpill-desktop/hardware-configuration.nix
   ```
3. Update the LUKS UUID in the host's `configuration.nix`
4. Hardware configs are automatically ignored by git (each machine keeps its own)
5. Rebuild with the appropriate flake target:
   - Laptop: `sudo nixos-rebuild switch --flake .#laptop`
   - Desktop: `sudo nixos-rebuild switch --flake .#desktop`

**Shared configuration:**
- All hosts share the same packages, dotfiles, and services (defined in `shared/`)
- Only hardware-specific settings and LUKS UUIDs differ between hosts

## Makefile Shortcuts

```bash
make rebuild    # Rebuild system
make update     # Update flake and rebuild
make clean      # Remove old generations
make help       # Show all commands
```

## Troubleshooting

**Can't login after changes:**
- At GRUB, select an older generation

**Docker permission denied:**
```bash
sudo usermod -aG docker $USER
# Log out and back in
```

**Network issues:**
```bash
sudo systemctl restart NetworkManager
```

**Rollback changes:**
```bash
sudo nixos-rebuild switch --rollback
```

## Btrfs Snapshots (Optional)

Take snapshots before major changes:

```bash
# Create a snapshot
sudo btrfs subvolume snapshot /home /home/.snapshots/home-$(date +%Y%m%d)

# List snapshots
sudo btrfs subvolume list /

# Restore from snapshot (boot into live USB if needed)
sudo btrfs subvolume delete /home
sudo btrfs subvolume snapshot /home/.snapshots/home-20241121 /home
```

For automatic snapshots, consider tools like:
- `snapper` - Automatic snapshot management
- `btrbk` - Backup tool for btrfs

## Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Home Manager](https://nix-community.github.io/home-manager/)
- [Search Packages](https://search.nixos.org/)
- [NixOS Discourse](https://discourse.nixos.org/)

## License

MIT - Feel free to use and modify!
