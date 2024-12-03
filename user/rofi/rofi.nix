{ config, pkgs, ... }:

{

	programs.rofi = {
		enable = true;
		theme = "../../.dotfiles/user/rofi/dracula.rasi";
	};

}
