# Milestone 3: clipboard history. wl-paste --watch cliphist store is the
# standard, stable pattern for this tool combination (not Hyprland/Quickshell
# API surface, so lower risk than other Milestone 3 pieces) -- confirmed via
# `cliphist --help` and `wl-paste --help` against the actual pinned packages.
{ config, pkgs, ... }:

{
  home.packages = [ pkgs.cliphist pkgs.wl-clipboard ];

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
