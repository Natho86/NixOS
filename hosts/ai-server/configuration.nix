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

  networking.hostName = "ai-server";
  networking.networkmanager.enable = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Required for the proprietary NVIDIA driver and other unfree GPU tooling.
  nixpkgs.config.allowUnfree = true;

  time.timeZone = "Europe/London";

  users.users.nath = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;

  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    curl
    htop
    pciutils
    usbutils
    nvtopPackages.nvidia
    ollama
  ];

  # NVIDIA RTX 3080 support.
  hardware.graphics.enable = true;

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;

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
      11434 # Ollama API
    ];

    # Services bound to 0.0.0.0 are reachable only via tailscale0,
    # not your normal LAN interface.
    trustedInterfaces = [ config.services.tailscale.interfaceName ];
  };

  # Local model server.
  services.ollama = {
    enable = true;
    package = pkgs.ollama-cuda;

    # Needed so VS Code / Continue on another Tailscale device can use it.
    host = "0.0.0.0";
    port = 11434;
    openFirewall = false;

    loadModels = [
      "qwen2.5-coder:7b"
      "llama3.1:8b"
      "mistral:7b"
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
