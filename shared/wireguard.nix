{ config, lib, pkgs, ... }:

let
  cfg = config.my.wireguard;
in
{
  options.my.wireguard = {
    enable = lib.mkEnableOption "WireGuard lab interface";

    autoStart = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to start the WireGuard interface automatically at boot.";
    };

    interfaceName = lib.mkOption {
      type = lib.types.str;
      default = "wg-lab";
      description = "Name of the WireGuard interface.";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."wireguard/privateKey" = {
      owner = "root";
      group = "root";
      mode = "0400";
    };

    networking.wireguard.interfaces.${cfg.interfaceName} = {
      ips = [ "198.51.100.3/32" ];
      privateKeyFile = config.sops.secrets."wireguard/privateKey".path;

      peers = [
        {
          publicKey = "PeJQZAyAzA9hDx7qeOSBX1toP4Q5ie3g7PJMsZj/G34=";
          allowedIPs = [ "10.2.0.0/16" "198.51.100.1/32" ];
          endpoint = "192.168.50.6:51820";
          persistentKeepalive = 25;
        }
      ];
    };

    systemd.services."wg-quick-${cfg.interfaceName}".wantedBy =
      lib.mkIf (!cfg.autoStart) (lib.mkForce [ ]);

    environment.systemPackages = [ pkgs.wireguard-tools ];
  };
}
