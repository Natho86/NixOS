{ pkgs, ... }: {
  networking.wg-quick.interfaces.wg0.configFile = "/home/nath/LUDUS/GOAD/goad.conf";
}
