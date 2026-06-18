{ config, lib, pkgs, ... }:

let
  dataDir = "/var/lib/automatic1111";
  composeFile = "${dataDir}/docker-compose.yml";

  hostAddress = "192.168.50.143";
  port = 7860;

  dockerComposeYaml = pkgs.writeText "automatic1111-docker-compose.yml" ''
    services:
      automatic1111:
        image: ghcr.io/ai-dock/stable-diffusion-webui:latest-cuda
        container_name: automatic1111
        restart: unless-stopped

        ports:
          - "${hostAddress}:${toString port}:${toString port}"

        environment:
          WEBUI_PORT_HOST: "${toString port}"
          WEBUI_ARGS: "--listen --port ${toString port} --xformers --medvram --api"
          PUID: "1001"
          PGID: "100"

        volumes:
          - ${dataDir}/workspace:/workspace
          - ${dataDir}/models:/opt/stable-diffusion-webui/models
          - ${dataDir}/outputs:/opt/stable-diffusion-webui/outputs
          - ${dataDir}/extensions:/opt/stable-diffusion-webui/extensions

        devices:
          - nvidia.com/gpu=all

        shm_size: "8g"
  '';
in
{
  hardware.nvidia-container-toolkit.enable = true;

  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  environment.systemPackages = with pkgs; [
    docker-compose
  ];

  systemd.tmpfiles.rules = [
    "d ${dataDir} 0755 root root -"
    "d ${dataDir}/workspace 0755 1001 100 -"
    "d ${dataDir}/models 0755 1001 100 -"
    "d ${dataDir}/outputs 0755 1001 100 -"
    "d ${dataDir}/extensions 0755 1001 100 -"
    "C ${composeFile} 0644 root root - ${dockerComposeYaml}"
  ];

  systemd.services.automatic1111 = {
    description = "AUTOMATIC1111 Stable Diffusion WebUI";
    wantedBy = [ "multi-user.target" ];
    after = [
      "docker.service"
      "network-online.target"
    ];
    wants = [
      "docker.service"
      "network-online.target"
    ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      WorkingDirectory = dataDir;

      ExecStart = "${pkgs.docker-compose}/bin/docker-compose -f ${composeFile} up -d";
      ExecStop = "${pkgs.docker-compose}/bin/docker-compose -f ${composeFile} down";

      TimeoutStartSec = "15min";
      TimeoutStopSec = "2min";
    };
  };
}
