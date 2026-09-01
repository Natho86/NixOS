# Milestone 3: wallpaper service. Config format verified against upstream
# hyprpaper wiki doc (content/hypr-ecosystem/user/hyprpaper.md) -- classic
# hyprlang, like hyprlock/hypridle, not Lua.
#
# Placeholder wallpaper: a solid Tokyo Night background colour, generated
# reproducibly at build time rather than committing a binary image to the
# repo. Swap `wallpaper` below for a real image path once one is chosen;
# no other config changes needed.
{ config, pkgs, ... }:

let
  placeholderWallpaper = pkgs.runCommand "omarchy-placeholder-wallpaper.png" { } ''
    ${pkgs.imagemagick}/bin/magick -size 1920x1200 xc:'#1a1b26' "$out"
  '';
in
{
  services.hyprpaper = {
    enable = true;
    settings = {
      ipc = "on";
      splash = false;

      # Confirmed shape (Home Manager's own test fixture,
      # tests/modules/services/hyprpaper/basic-configuration.nix): every
      # image used in `wallpaper` must also be listed in `preload`.
      preload = [ "${placeholderWallpaper}" ];

      wallpaper = [
        {
          monitor = "";
          path = "${placeholderWallpaper}";
          fit_mode = "cover";
        }
      ];
    };
  };
}
