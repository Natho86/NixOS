# Milestone 6 (partial): expand rofi (SUPER+SPACE, bound since Milestone
# 1) from apps-only into a combined apps/commands/windows launcher, using
# rofi's own built-in combi mode -- confirmed real via `rofi -help`
# (modes listed: window, run, combi, keys, filebrowser), not a custom
# Quickshell launcher. Milestone 2's own research found no first-party
# Quickshell app-search module, so extending the already-working rofi
# setup is lower-risk than building one from scratch.
{
  config,
  pkgs,
  lib,
  ...
}:

let
  omarchyTheme = (import ./themes/default.nix).theme;
  inherit (config.lib.formats.rasi) mkLiteral;
in
{
  programs.rofi = {
    enable = true;
    package = pkgs.rofi;

    # combi presents drun (applications) and run (shell commands) results
    # together in one list; window is kept as a separate mode, bound
    # below, rather than folded into combi, since mixing "switch to an
    # existing window" with "launch a new one" in the same result list
    # risks accidentally launching a duplicate of something already open.
    #
    # clipboard is a script mode (omarchy-rofi-clipboard, clipboard.nix)
    # registered as "clipboard:<script>" per `man rofi-script` -- kept as
    # its own named mode (Ctrl+Tab to cycle to it from SUPER+SPACE) rather
    # than folded into combi, matching the reasoning above for window.
    modes = [
      "combi"
      "window"
      "clipboard:omarchy-rofi-clipboard"
    ];

    extraConfig = {
      combi-modes = [
        "drun"
        "run"
      ];
      show-icons = true;
    };

    # Milestone 7 follow-up: rofi previously had no `theme` set at all,
    # so every rofi surface (launcher, window switcher, clipboard picker,
    # power menu, theme-adjacent pickers) rendered with rofi's own
    # built-in default look -- reported by the user as "no noticible
    # difference" when switching themes, alongside Alacritty (fixed
    # separately in shared/home.nix). This theme block is this repo's own
    # construction (upstream Omarchy doesn't use rofi at all -- Milestone
    # 2 found no first-party Quickshell launcher, so this repo substitutes
    # rofi where Omarchy has nothing to port from), built from the same
    # themes/default.nix tokens every other consumer reads, using
    # Home Manager's own documented mkLiteral pattern (see this option's
    # own doc example in modules/programs/rofi.nix) for unquoted rasi
    # values like colours and literal identifiers.
    theme =
      let
        bg = mkLiteral omarchyTheme.colors.background;
        bgAlt = mkLiteral omarchyTheme.colors.surface;
        fg = mkLiteral omarchyTheme.colors.foreground;
        accent = mkLiteral omarchyTheme.colors.accent;
        border = mkLiteral omarchyTheme.colors.border;
      in
      {
        "*" = {
          background-color = mkLiteral "transparent";
          text-color = fg;
          font = mkLiteral "\"${omarchyTheme.font.monoFamily} ${toString omarchyTheme.font.size}\"";
        };

        window = {
          background-color = bg;
          border = mkLiteral "${toString omarchyTheme.layout.borderSize}px";
          border-color = accent;
          border-radius = mkLiteral "${toString omarchyTheme.layout.rounding}px";
          width = mkLiteral "40%";
        };

        mainbox = {
          background-color = mkLiteral "transparent";
          padding = mkLiteral "${toString omarchyTheme.layout.gapsIn}px";
        };

        inputbar = {
          background-color = bgAlt;
          text-color = fg;
          border-radius = mkLiteral "${toString omarchyTheme.layout.rounding}px";
          padding = mkLiteral "8px 12px";
          children = map mkLiteral [
            "prompt"
            "entry"
          ];
        };

        prompt.text-color = accent;
        entry.placeholder = mkLiteral "\"Search\"";

        listview = {
          background-color = mkLiteral "transparent";
          border = mkLiteral "0px";
          spacing = mkLiteral "4px";
        };

        element = {
          padding = mkLiteral "6px 10px";
          border-radius = mkLiteral "${toString omarchyTheme.layout.rounding}px";
        };

        "element normal.normal" = {
          background-color = mkLiteral "transparent";
          text-color = fg;
        };

        "element selected.normal" = {
          background-color = accent;
          text-color = bg;
        };

        "element alternate.normal" = {
          background-color = mkLiteral "transparent";
          text-color = fg;
        };
      };
  };
}
