{ config, pkgs, ... }:
{
  boot.initrd.kernelModules = ["8812au"];
  boot.extraModulePackages = [
    config.boot.kernelPackages.rtl88xxau-aircrack
    config.boot.kernelPackages.rtl8812au
    config.boot.kernelPackages.rtl8821au
  ];

  environment.systemPackages = [
    pkgs.wirelesstools
    pkgs.iw
    pkgs.aircrack-ng
    pkgs.wifite2
  ];

}
