# Milestone 4: Catppuccin Mocha theme tokens -- proves the theme interface
# is not hard-coded to Tokyo Night. Colours reused verbatim from
# shared/qtile-config.py's existing Catppuccin Mocha palette (already used
# for Qtile's bar/borders and the Catppuccin GTK/cursor packages installed
# in shared/home.nix), so selecting this theme would actually unify the
# desktop's look with what Qtile/Plasma already show, not add a third
# distinct palette.
{
  name = "catppuccin";

  colors = {
    background = "#1e1e2e"; # base
    foreground = "#cdd6f4"; # text
    surface = "#313244"; # surface0
    overlay = "#45475a"; # surface1

    accent = "#89b4fa"; # blue
    muted = "#6c7086"; # overlay0
    urgent = "#f38ba8"; # red
    success = "#a6e3a1"; # green
    warning = "#f9e2af"; # yellow

    border = "#313244"; # surface0
    borderActive = "#89b4fa"; # blue
  };

  opacity = {
    borderActive = 0.93;
    borderInactive = 0.67;
    surface = 0.8;
  };

  font = {
    family = "Sans";
    monoFamily = "JetBrainsMono Nerd Font";
    size = 13;
    sizeLarge = 20;
  };

  layout = {
    gapsIn = 8; # matches qtile-config.py's Columns layout margin
    gapsOut = 8;
    borderSize = 2;
    rounding = 8;
    barHeight = 30; # matches qtile-config.py's bar height exactly
  };
}
