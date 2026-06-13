{ ... }:

{
  systemd.tmpfiles.rules = [
    # nath:users on ai-server
    "d /var/lib/paperless-ai 0750 1001 100 -"
    "d /home/nath/.config/paperless-ai 0700 1001 100 -"
  ];

  virtualisation.oci-containers.backend = "docker";

  virtualisation.oci-containers.containers.paperless-ai = {
    image = "clusterzx/paperless-ai:latest";
    pull = "newer";
    autoStart = true;

    ports = [
      "3000:3000"
    ];

    volumes = [
      "/var/lib/paperless-ai:/app/data"
    ];

    environment = {
      PUID = "1001";
      PGID = "100";

      PAPERLESS_AI_PORT = "3000";

      RAG_SERVICE_ENABLED = "true";
      RAG_SERVICE_URL = "http://localhost:8000";

      PAPERLESS_AI_INITIAL_SETUP = "yes";

      PAPERLESS_API_URL = "http://192.168.50.4:8000/api";

      # From inside Docker, localhost is the container itself.
      # Use the ai-server LAN address for Ollama.
      OLLAMA_API_URL = "http://192.168.50.143:11434";
      OLLAMA_MODEL = "gemma4:12b";

      AI_PROVIDER = "ollama";

      SCAN_INTERVAL = "*/30 * * * *";

      PROCESS_PREDEFINED_DOCUMENTS = "yes";
      ADD_AI_PROCESSED_TAG = "yes";
      AI_PROCESSED_TAG_NAME = "ai-processed";
    };

    extraOptions = [
      "--env-file=/home/nath/.config/paperless-ai/paperless-ai.env"
      "--cap-drop=ALL"
      "--security-opt=no-new-privileges=true"
    ];
  };
}
