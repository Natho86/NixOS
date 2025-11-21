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
cd /mnt
mkdir -p home
cd home
git clone https://github.com/yourusername/nixos-config.git
cd nixos-config
```

**4. Generate hardware config:**
```bash
nixos-generate-config --root /mnt
cp /mnt/etc/nixos/hardware-configuration.nix ./
```

**5. Customize configuration:**
```bash
# Get your LUKS UUID
blkid ${DISK}p2

# Edit configuration.nix and update:
# - YOUR-LUKS-UUID-HERE (line ~25)
# - yourusername (multiple locations)
# - timezone (line ~36)

# Quick replace username:
USERNAME="yourname"
sed -i "s/yourusername/$USERNAME/g" *.nix

# Edit home.nix and update:
# - Git name and email
nano home.nix
```

**6. Install:**
```bash
nixos-install --flake .#laptop
# Set root password when prompted

# Set user password
nixos-enter --root /mnt -c "passwd $USERNAME"

# Reboot
reboot
```

### Option B: Existing NixOS System

**1. Clone this repository:**
```bash
git clone https://github.com/yourusername/nixos-config.git ~/nixos-config
cd ~/nixos-config
```

**2. Generate your hardware config:**
```bash
sudo nixos-generate-config --show-hardware-config > hardware-configuration.nix
```

**3. Customize configuration:**
```bash
# Get your LUKS UUID (if using encryption)
sudo blkid /dev/nvme0n1p2  # or your encrypted partition

# Update configuration.nix:
# - YOUR-LUKS-UUID-HERE with your actual UUID
# - yourusername with your actual username
# - timezone to your location

# Quick replace:
USERNAME="yourname"
sed -i "s/yourusername/$USERNAME/g" *.nix

# Update home.nix:
# - Git name and email
nano home.nix
```

**4. Test and apply:**
```bash
# Test the configuration
sudo nixos-rebuild test --flake .#laptop

# If everything works, apply it
sudo nixos-rebuild switch --flake .#laptop
```

## Post-Installation

### Essential Commands
```bash
# Rebuild system after changes
sudo nixos-rebuild switch --flake ~/nixos-config#laptop

# Update all packages
cd ~/nixos-config
nix flake update
sudo nixos-rebuild switch --flake .#laptop

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

Edit `home.nix` and add to `home.packages`:
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
sudo nixos-rebuild switch --flake ~/nixos-config#laptop
```

## File Structure

```
nixos-config/
├── flake.nix                    # Flake definition
├── configuration.nix            # System configuration
├── home.nix                     # User environment
├── qtile-config.py             # Qtile config
├── hardware-configuration.nix   # Auto-generated (not in git)
├── .gitignore                  # Protects secrets
├── Makefile                    # Shortcuts
└── secrets/
    └── secrets.yaml            # Encrypted secrets
```

## Secrets Management (Optional)

Setup sops-nix for encrypted secrets:

```bash
# Generate age key
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
age-keygen -y ~/.config/sops/age/keys.txt  # Get public key

# Create .sops.yaml with your public key
cat > ~/nixos-config/.sops.yaml << 'EOF'
keys:
  - &admin YOUR_PUBLIC_KEY_HERE
creation_rules:
  - path_regex: secrets/secrets.yaml$
    key_groups:
    - age:
      - *admin
EOF

# Edit secrets (auto-encrypted on save)
cd ~/nixos-config
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

## Customization

**Change timezone:**
```nix
# In configuration.nix
time.timeZone = "America/Los_Angeles";
```

**Adjust power management:**
```nix
# In configuration.nix
services.tlp.settings = {
  START_CHARGE_THRESH_BAT0 = 40;
  STOP_CHARGE_THRESH_BAT0 = 80;
};
```

**Change theme:** Edit colors in `home.nix` and `qtile-config.py`

## Multiple Machines

Since `hardware-configuration.nix` is machine-specific:

1. Clone the repo on each machine
2. Generate `hardware-configuration.nix` locally
3. It's automatically ignored by git
4. Each machine keeps its own hardware config

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
