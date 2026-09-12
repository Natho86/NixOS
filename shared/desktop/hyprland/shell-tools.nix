# Milestone 2 (remaining scope): reload command and log helper for
# Quickshell, matching the plan's "failure logging and a clean way to
# restart Quickshell without restarting Hyprland" deliverable.
# `systemctl --user restart quickshell` (the raw command used throughout
# this session's manual testing) is what actually restarts it -- these
# wrap it plus `qs log` (confirmed real via `qs log --help`) into
# memorable commands instead of requiring the raw systemctl/qs incantation.
{
  config,
  pkgs,
  lib,
  ...
}:

let
  reload = pkgs.writeShellApplication {
    name = "desktop-shell-reload";
    runtimeInputs = [ pkgs.systemd ];
    text = ''
      echo "Restarting Quickshell..."
      systemctl --user restart quickshell
      echo "Done. Use desktop-shell-log to check for errors."
    '';
  };

  shellLog = pkgs.writeShellApplication {
    name = "desktop-shell-log";
    runtimeInputs = [ pkgs.quickshell ];
    text = ''
      # -c desktop required: `qs log` defaults to a config named "default"
      # if none is given, but activeConfig is "desktop" (home.nix) --
      # confirmed live: without it, fails with "Could not find 'default'
      # config directory or shell.qml in any valid config path."
      # -f (follow) by default for interactive debugging; pass -t N to
      # just tail N lines and exit instead, e.g. `desktop-shell-log -t 50`.
      qs -c desktop log -f "$@"
    '';
  };
in
{
  home.packages = [
    reload
    shellLog
  ];
}
