{ config, pkgs, ... }:

{

	programs.kitty = {
		enable = true;
		themeFile = "snazzy";
		font = {
			name = "MesloLG Nerd Font";
			size = 10;
    };
    extraConfig = ''
    include ~/.dotfiles/user/kitty/snazzy.conf
    window_padding_width 6
    background_opacity 0.9
    '';
	};

}
