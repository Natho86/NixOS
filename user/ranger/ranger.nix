{ inputs, pkgs, ... }:

{
  programs.ranger = {
    enable = true;
    extraPackages = with pkgs; [
      ueberzugpp
    ];
    extraConfig = ''
      set preview_images true
      set preview_images_method ueberzug
      set preview_max_size 10000000
      set draw_borders both
      default_linemode devicons
    '';
  };
}

