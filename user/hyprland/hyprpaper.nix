{ config, pkgs, ... }:

{
  
  services.hyprpaper = {
    enable = true;
    settings = {
      ipc = "on";
      splash = false;
      splash_offset = 2.0;

      preload =
        [ "~/.dotfiles/user/wallpaper/trees.png" ];

      wallpaper = [ ",~/.dotfiles/user/wallpaper/trees.png" ];
    };
  };
}
