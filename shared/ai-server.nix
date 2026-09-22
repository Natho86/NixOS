{ config, lib, pkgs, ... }:

let
  cfg = config.my.aiServer;
in
{
  options.my.aiServer.enable = lib.mkEnableOption "the local AI server role";

  config = lib.mkIf cfg.enable {
    # The model is deliberately stored outside /nix/store so it can be
    # replaced without rebuilding the operating system.
    environment.systemPackages = [ pkgs.llama-cpp ];

    services.llama-cpp = {
      enable = true;
      package = pkgs.llama-cpp;
      openFirewall = false;
      settings = {
        host = "0.0.0.0";
        port = 8081;
        model = "/var/lib/llama-cpp/models/qwen2.5-coder-7b-instruct-q4_k_m.gguf";
        # Hermes Agent requires at least 64K context for tool use.
        ctx-size = 65536;
        model = "/var/lib/llama-cpp/models/Qwen3-8B-Q4_K_M.gguf";
        ctx-size = 65536;
        n-gpu-layers = 999;
        flash-attn = "on";
        parallel = 2;
      };
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/llama-cpp/models 0755 root root -"
    ];

    # The API is reachable remotely over Tailscale, but not through ordinary
    # LAN interfaces. Open WebUI accesses it locally on 127.0.0.1.
    networking.firewall.interfaces.${config.services.tailscale.interfaceName}.allowedTCPPorts = [ 8081 ];

    systemd.services.llama-cpp = {
      after = [ "nvidia-persistenced.service" ];
      requires = [ "nvidia-persistenced.service" ];
      serviceConfig.ExecStartPre = [
        "/bin/sh -lc 'for device in /dev/nvidiactl /dev/nvidia0 /dev/nvidia-uvm; do for i in $(seq 1 50); do [ -e $device ] && break; sleep 0.1; done; [ -e $device ] || { echo $device not found; exit 1; }; done'"
      ];
    };

    services.open-webui = {
      enable = true;
      host = "0.0.0.0";
      port = 8080;
      openFirewall = true;

      environment = {
        OPENAI_API_BASE_URL = "http://127.0.0.1:8081/v1";
        WEBUI_AUTH = "True";
        ANONYMIZED_TELEMETRY = "False";
        DO_NOT_TRACK = "True";
        SCARF_NO_ANALYTICS = "True";
      };
    };
  };
}
