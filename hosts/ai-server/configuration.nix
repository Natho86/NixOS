{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  system.stateVersion = "25.11";

  boot.loader = {
    systemd-boot.enable = true;
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
    #cudaSupport = true;
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

  programs.zsh.enable = true;

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
    
    # for running osintdb dev project /home/nath/dev
    nodejs
    docker-compose

    # Coding agents
    codex
    claude-code
    claude-monitor

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

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;

    # Keep the GPU initialized for headless inference services such as Ollama.
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
      #11434 # Ollama API
    ];

    # Services bound to 0.0.0.0 are reachable only via tailscale0,
    # not your normal LAN interface.
    trustedInterfaces = [ config.services.tailscale.interfaceName ];
  };

  # Local model server.
  services.ollama = {
    enable = true;
    package = pkgs.ollama-cuda;

    # Force Ollama to load the CUDA runner instead of silently falling back to CPU.
    environmentVariables = {
      CUDA_VISIBLE_DEVICES = "0";
      OLLAMA_FLASH_ATTENTION = "1";
      OLLAMA_LLM_LIBRARY =
        "cuda_v${lib.versions.major pkgs.cudaPackages.cuda_cudart.version}";
    };

    # Needed so VS Code / Continue on another Tailscale device can use it.
    host = "0.0.0.0";
    port = 11434;
    openFirewall = true;

    loadModels = [
      "qwen2.5-coder:7b"
      "llama3.1:8b"
      "mistral:7b"
    ];
  };

  # Ensure the headless Ollama service starts only after NVIDIA device nodes exist.
  systemd.services.ollama = {
    after = [ "nvidia-persistenced.service" ];
    requires = [ "nvidia-persistenced.service" ];
    serviceConfig.ExecStartPre = [
      "/bin/sh -lc 'for device in /dev/nvidiactl /dev/nvidia0 /dev/nvidia-uvm; do for i in $(seq 1 50); do [ -e $device ] && break; sleep 0.1; done; [ -e $device ] || { echo $device not found; exit 1; }; done'"
    ];
  };

  # ChatGPT-like web UI.
  services.open-webui = {
    enable = true;
    host = "0.0.0.0";
    port = 8080;
    openFirewall = true;

    environment = {
      OLLAMA_BASE_URL = "http://127.0.0.1:11434";
      WEBUI_AUTH = "True";
      ANONYMIZED_TELEMETRY = "False";
      DO_NOT_TRACK = "True";
      SCARF_NO_ANALYTICS = "True";
    };
  };

  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "no";
    };
  };
}
