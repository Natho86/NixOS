{ pkgs, ... }: {
  networking.wg-quick.interfaces.wg0.configFile = "/home/nath/.dotfiles/wg0.conf";
}
