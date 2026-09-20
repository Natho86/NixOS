{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    # This is a second role for the same physical machine as redpill-desktop.
    # Keep the machine's disk, boot, and hardware declarations in one place.
    ../redpill-desktop/hardware-configuration.nix
    ../../shared/ai-server.nix
  ];

  my.aiServer.enable = true;

  system.stateVersion = "25.11";

  boot.loader = {
    systemd-boot.enable = true;
    systemd-boot.configurationLimit = 10;
    efi.canTouchEfiVariables = true;
  };

  # Preload NVIDIA's Unified Virtual Memory module for CUDA workloads and
  # AMD/Nuvoton temperature sensor modules commonly needed by this server.
  boot.kernelModules = [
    "nvidia_uvm"
    "k10temp"
    "nct6775"
  ];

  # Expose I2C/SMBus devices for lm_sensors and liquidctl so CPU,
  # motherboard, pump, and fan telemetry is available from SSH sessions.
  hardware.i2c.enable = true;

  networking.hostName = "ai-server";
  networking.networkmanager.enable = true;

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];

    max-jobs = 1;
    cores = 4;
  };

  # Persistent swap for large local builds.
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 32 * 1024; # 32 GiB, size is in MiB
      priority = 10;
    }
  ];

  # Prefer RAM where possible, but allow swap as a safety net during builds.
  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
  };

  # Put memory pressure from nix-daemon and its build children under a cgroup
  # ceiling so rebuilds cannot consume all RAM and make SSH recovery impossible.
  systemd.services.nix-daemon.serviceConfig = {
    MemoryHigh = "75%";
    MemoryMax = "85%";
    OOMPolicy = "continue";
  };

  # Required for the proprietary NVIDIA driver and CUDA-enabled packages.
  nixpkgs.config = {
    allowUnfree = true;
    cudaSupport = true;
  };

  time.timeZone = "Europe/London";

  users.users.nath = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "i2c"
      "docker"
    ];
    shell = pkgs.zsh;
  };

  # Install udev rules from liquidctl so supported AIO coolers expose status
  # and pump/fan telemetry without needing root for every read.
  services.udev.packages = [ pkgs.liquidctl ];

  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    curl
    htop
    btop
    pciutils
    usbutils
    tmux
    sops
    jq
    tree
    eza
    bat
    ripgrep

    # for running osintdb dev project /home/nath/dev
    nodejs
    docker-compose

    # Coding agents
    codex
    claude-code
    claude-monitor

    # fonts
    nerd-fonts.fira-code
    nerd-fonts.hack
    nerd-fonts.jetbrains-mono
    #nerd-fonts-color-emoji
    font-awesome

    # Temperature, fan, pump, and stress/thermal monitoring tools.
    lm_sensors
    liquidctl
    s-tui
    stress-ng
    smartmontools
    nvtopPackages.nvidia
  ];

  virtualisation.docker = {
    enable = true;
    daemon.settings = {
      log-driver = "journald";
    };
  };

  # NVIDIA RTX 3080 support.
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.nvidia-container-toolkit.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;

    # Keep the GPU initialized for the headless llama.cpp inference service.
    nvidiaPersistenced = true;

    # For RTX 3080, use the proprietary NVIDIA kernel module.
    # NixOS now requires explicitly choosing open/proprietary.
    open = false;

    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Tailscale-only remote access.
  services.tailscale.enable = true;

  networking.firewall = {
    enable = true;

    # Allow Tailscale itself.
    allowedUDPPorts = [ config.services.tailscale.port ];

    allowedTCPPorts = [
      3003 # immich ML
    ];

    # Services bound to 0.0.0.0 are reachable only via tailscale0,
    # not your normal LAN interface.
    trustedInterfaces = [ config.services.tailscale.interfaceName ];
  };

  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "no";
    };
  };

  # Zsh configuration
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ll = "eza -l --icons=always";
      la = "eza -la --icons=always";
      ls = "eza --icons=always -l";
      cat = "bat";

      # NixOS specific
      rebuild = "sudo nixos-rebuild switch --flake ~/nixos-config#laptop";
      update = "nix flake update ~/nixos-config && sudo nixos-rebuild switch --flake ~/nixos-config#laptop";
      clean = "sudo nix-collect-garbage -d";

      # Git shortcuts
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git log --oneline --graph";
    };

    ohMyZsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [
        "git"
        "docker"
        "docker-compose"
        "sudo"
        "history"
        "colored-man-pages"
      ];
    };

    #initContent = ''
    #  # Starship prompt
    #  eval "$(starship init zsh)"
    #
    #  # FZF keybindings
    #  source ${pkgs.fzf}/share/fzf/key-bindings.zsh
    #  source ${pkgs.fzf}/share/fzf/completion.zsh
    #'';
  };

  # Starship prompt
  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;
      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[➜](bold red)";
      };
      package.disabled = true;
    };
  };

  # Fonts
  fonts.fontconfig.enable = true;

}
