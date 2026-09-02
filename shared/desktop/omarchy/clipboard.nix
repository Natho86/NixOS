# Milestone 3: clipboard history. wl-paste --watch cliphist store is the
# standard, stable pattern for this tool combination (not Hyprland/Quickshell
# API surface, so lower risk than other Milestone 3 pieces) -- confirmed via
# `cliphist --help` and `wl-paste --help` against the actual pinned packages.
#
# Milestone 6: clipboard history as a rofi script-mode, so it can appear as
# a mode alongside combi/window rather than only as its own separate
# SUPER+V picker. Protocol confirmed via `man rofi-script`: called with no
# args on the initial listing, then re-invoked with the *selected line's
# text* as $@ once chosen. cliphist's own `list` output ("<id>\t<preview>")
# is exactly what rofi should display verbatim, and that same line piped
# back into `cliphist decode` reproduces the original content -- confirmed
# directly (`cliphist list | head -1 | cliphist decode`) before wiring this
# up, not assumed. SUPER+V is kept as-is (direct dmenu picker) alongside
# this, since it's established muscle memory and the plan only asks for
# clipboard history to be reachable as a launcher mode, not for the
# standalone bind to be removed.
{ config, pkgs, ... }:

let
  clipboardMode = pkgs.writeShellApplication {
    name = "omarchy-rofi-clipboard";
    runtimeInputs = [ pkgs.cliphist pkgs.wl-clipboard ];
    text = ''
      if [ "$#" -eq 0 ]; then
        cliphist list
      else
        printf '%s' "$1" | cliphist decode | wl-copy
      fi
    '';
  };
in
{
  home.packages = [ pkgs.cliphist pkgs.wl-clipboard clipboardMode ];

  systemd.user.services.cliphist = {
    Unit = {
      Description = "Clipboard history daemon (cliphist)";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --watch ${pkgs.cliphist}/bin/cliphist store";
      Restart = "on-failure";
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };
}
