# Milestone 6 (partial): expand rofi (SUPER+SPACE, bound since Milestone
# 1) from apps-only into a combined apps/commands/windows launcher, using
# rofi's own built-in combi mode -- confirmed real via `rofi -help`
# (modes listed: window, run, combi, keys, filebrowser), not a custom
# Quickshell launcher. Milestone 2's own research found no first-party
# Quickshell app-search module, so extending the already-working rofi
# setup is lower-risk than building one from scratch.
{ config, pkgs, lib, ... }:

{
  programs.rofi = {
    enable = true;
    package = pkgs.rofi;

    # combi presents drun (applications) and run (shell commands) results
    # together in one list; window is kept as a separate mode, bound
    # below, rather than folded into combi, since mixing "switch to an
    # existing window" with "launch a new one" in the same result list
    # risks accidentally launching a duplicate of something already open.
    modes = [ "combi" "window" ];

    extraConfig = {
      combi-modes = [ "drun" "run" ];
      show-icons = true;
    };
  };
}
