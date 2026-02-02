# Edit configuration.nix to add further configuration options.
{ config, lib, pkgs, inputs, ... }:

{
  # imports = [
  #  ./hardware-configuration.nix
  #];

  # Enable GPU
  hardware.graphics.enable = true;

  # Bootloader with LUKS support
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # LUKS encryption setup moved to host-specific configuration
  # See hosts/redpill-x1-yoga/configuration.nix or hosts/redpill-desktop/configuration.nix

  # Networking
  #networking.hostName = "redpill-x1-yoga";
  networking.networkmanager.enable = true;

  # Tailscale VPN
  services.tailscale.enable = true;

  # Time zone and locale
  time.timeZone = "Europe/London"; # Change to your timezone
  i18n.defaultLocale = "en_GB.UTF-8";
  
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_GB.UTF-8";
    LC_IDENTIFICATION = "en_GB.UTF-8";
    LC_MEASUREMENT = "en_GB.UTF-8";
    LC_MONETARY = "en_GB.UTF-8";
    LC_NAME = "en_GB.UTF-8";
    LC_NUMERIC = "en_GB.UTF-8";
    LC_PAPER = "en_GB.UTF-8";
    LC_TELEPHONE = "en_GB.UTF-8";
    LC_TIME = "en_GB.UTF-8";
  };

  console.keyMap = "uk";

  # Enable the X11 windowing system
  services.xserver.enable = true;
  services.xserver.xkb.layout = "gb";
  
  # Enable Plasma 6
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.desktopManager.plasma6.enable = true;
  
  # Enable Qtile
  services.xserver.windowManager.qtile.enable = true;

  # Auto-login configuration is set per-host (see laptop config)

  # Audio
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Enable Docker
  virtualisation.docker.enable = true;

  # Enable touchpad support
  services.libinput.enable = true;

  # Define a user account
  users.users.nath = {
    isNormalUser = true;
    description = "Nath";
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "docker" ];
    shell = pkgs.zsh;
  };

  # Allow unfree packages (needed for Chrome, 1Password, Obsidian, Spotify)
  nixpkgs.config.allowUnfree = true;

  # Flox 
  nix.settings.trusted-substituters = [ "https://cache.flox.dev" ];
  nix.settings.trusted-public-keys = [ "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs=" ];
  
  # https://flox.dev/docs/install-flox/install/#__codelineno-23-1
  # Install to user profile with:
  #  nix profile install \
  #    --experimental-features "nix-command flakes" \
  #    --accept-flake-config \
  #    'github:flox/flox/latest'
  
  # Mullvad-vpn https://nixos.wiki/wiki/Mullvad_VPN
  services.mullvad-vpn.enable = true;

  # System packages
  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    curl
    htop
    btop
    fd
    ripgrep
    code-cursor

    # ctfs/labs/courses
    openvpn
    
    # CLI utilities
    fzf
    eza
    bat

    # System utilities
    pciutils
    
    # Archive tools
    unzip
    p7zip

    # Media
    vlc

    # audacity + ffmpeg https://github.com/Seijji/nixos-config/blob/e1c6a2464320a0338be0778c7c5c74c3c76de6f5/configuration.nix#L206
    ffmpeg_6  # or ffmpeg_7, depending on what audacity needs
    (audacity.override {
      ffmpeg = ffmpeg_6;  # Match the version from ldd output
    })
  ];
  # https://github.com/Seijji/nixos-config/blob/e1c6a2464320a0338be0778c7c5c74c3c76de6f5/configuration.nix#L206
  nixpkgs.config.audacity.ffmpeg = pkgs.ffmpeg;

  # Mullvad-vpn https://nixos.wiki/wiki/Mullvad_VPN
  services.mullvad-vpn.package = pkgs.mullvad-vpn;

  # Enable programs
  programs.zsh.enable = true;
  programs.git.enable = true;

  # Set environment variables system-wide for proper terminal color support
  # Using sessionVariables ensures these are set early by PAM during login
  environment.sessionVariables = {
    TERM = "xterm-256color";
    COLORTERM = "truecolor";
  };

  # Also set in shell profile to override terminal emulator settings
  programs.zsh.interactiveShellInit = ''
    export TERM=xterm-256color
    export COLORTERM=truecolor
  '';
  
  # Enable 1Password
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "nath" ];
  };

  # Secrets management with sops-nix
  # Host-specific key paths are set in each host configuration
  sops = {
    defaultSopsFile = ./secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
  };

  # Enable firmware updates
  services.fwupd.enable = true;

  # Power management (TLP is configured per-host for laptops)

  # Enable bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Enable flakes and nix-command
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  # Automatic garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
  
  # Optimize store automatically
  nix.optimise.automatic = true;

  # Automatic system updates
  system.autoUpgrade = {
    enable = true;
    allowReboot = false;  # Don't automatically reboot (manual reboot required)
    dates = "weekly";     # Check for updates weekly
    flake = "github:Natho86/NixOS#${config.networking.hostName}";  # Update from GitHub repo
    # Alternatively, use local flake for testing before deploying:
    # flake = "/home/nath/NixOS#${config.networking.hostName}";
  };

  # Enable firewall
  networking.firewall.enable = true;
  # Allow Tailscale traffic
  networking.firewall.trustedInterfaces = [ "tailscale0" ];
  networking.firewall.allowedUDPPorts = [ 41641 ]; # Tailscale default port

  # This value determines the NixOS release
  system.stateVersion = "24.05";
}
