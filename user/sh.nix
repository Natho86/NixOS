{ config, pkgs, lib, ... }:

# Set aliases as variable to be used in multiple shell configs
let
	myAliases = {
		ll = "ls -l --color=auto";
		ls = "ls -lah --color=auto";
		lt = "ls -laht --color=auto";
		".." = "cd ..";
  };

  cfg = config.programs.kitty;
  inherit (lib) mkAfter;

in
{

	# Bash
	programs.bash = {
		enable = true;
		shellAliases = myAliases;
	};

	# ZSH
	programs.zsh = {
    enable = true;
    enableCompletion = true;
		shellAliases = myAliases;
    autosuggestion.enable = true;
    #autosuggestion.highlight = "fg=#ff00ff,bg=cyan,bold,underline";
		syntaxHighlighting.enable = true;
		plugins = [
			{
				name = "powerlevel10k";
				src = pkgs.zsh-powerlevel10k;
				file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
			}
			{
				name = "powerlevel10k-config";
				src = ./p10k-config;
				file = "p10k.zsh";
			}
    ];
    initExtra = mkAfter ''
      # Alias ssh command if using kitty
      [ "$TERM" = "xterm-kitty" ] && alias ssh="kitty +kitten ssh"
      # Alias diff command if using kitty
      [ "$TERM" = "xterm-kitty" ] && alias diff="kitty +kitten diff"
    '';
	};
}
