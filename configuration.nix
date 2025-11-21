# Edit configuration.nix to add further configuration options.
{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Bootloader with LUKS support
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  # LUKS encryption setup
  boot.initrd.luks.devices."cryptroot" = {
    device = "/dev/disk/by-uuid/YOUR-LUKS-UUID-HERE"; # Replace with your LUKS UUID
    preLVM = true;
    allowDiscards = true; # Improves SSD performance
  };

  # Networking
  networking.hostName = "laptop";
  networking.networkmanager.enable = true;

  # Time zone and locale
  time.timeZone = "America/New_York"; # Change to your timezone
  i18n.defaultLocale = "en_US.UTF-8";
  
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable the X11 windowing system
  services.xserver.enable = true;
  
  # Enable Plasma 6
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.desktopManager.plasma6.enable = true;
  
  # Enable Qtile
  services.xserver.windowManager.qtile.enable = true;
  
  # Auto-login after disk unlock
  services.displayManager.autoLogin = {
    enable = true;
    user = "yourusername"; # Replace with your username
  };
  
  # Workaround for auto-login with SDDM
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

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
  
  # Add user to docker group
  users.users.yourusername.extraGroups = [ "docker" ];

  # Enable touchpad support
  services.libinput.enable = true;

  # Define a user account
  users.users.yourusername = {
    isNormalUser = true;
    description = "Your Name";
    extraGroups = [ "networkmanager" "wheel" "video" "audio" ];
    shell = pkgs.zsh;
  };

  # Allow unfree packages (needed for Chrome, 1Password, Obsidian, Spotify)
  nixpkgs.config.allowUnfree = true;

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
    
    # CLI utilities
    fzf
    eza
    bat
    
    # Archive tools
    unzip
    p7zip
  ];

  # Enable programs
  programs.zsh.enable = true;
  programs.git.enable = true;
  
  # Enable 1Password
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "yourusername" ];
  };

  # Secrets management with sops-nix
  sops = {
    defaultSopsFile = ./secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/home/yourusername/.config/sops/age/keys.txt";
  };

  # Enable firmware updates
  services.fwupd.enable = true;

  # Power management for laptop
  services.power-profiles-daemon.enable = false; # Conflicts with TLP
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      
      START_CHARGE_THRESH_BAT0 = 40;
      STOP_CHARGE_THRESH_BAT0 = 80;
    };
  };

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

  # Enable firewall
  networking.firewall.enable = true;

  # This value determines the NixOS release
  system.stateVersion = "24.05";
}
