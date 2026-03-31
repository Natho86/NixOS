{ config, lib, pkgs, ... }:

let
  wgInterface = "wg-lab";
in
{
  networking.wireguard.interfaces.${wgInterface} = {
    ips = [ "198.51.100.3/32" ]; # adjust to your lab subnet
    privateKeyFile = config.sops.secrets."wireguard/privateKey".path;

    peers = [
      {
        publicKey = "PeJQZAyAzA9hDx7qeOSBX1toP4Q5ie3g7PJMsZj/G34=";
        allowedIPs = [ "10.2.0.0/16", "198.51.100.1/32" ]; # lab network
        endpoint = "192.168.50.6:51820";
        persistentKeepalive = 25;
      }
    ];
  };

  # DO NOT auto-start
  systemd.services."wg-quick-${wgInterface}".wantedBy = lib.mkForce [ ];

  # Ensure tools installed
  environment.systemPackages = [ pkgs.wireguard-tools ];
}
