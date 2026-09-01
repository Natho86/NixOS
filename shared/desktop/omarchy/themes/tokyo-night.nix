# Milestone 4: Tokyo Night theme tokens. Colours match what was already
# hand-copied across shell/{Bar,Notifications,Osd}.qml and home.nix's
# Hyprland border colours in Milestones 1-3; consolidated here as the
# single source of truth those files should read from instead.
{
  name = "tokyo-night";

  colors = {
    background = "#1a1b26";
    foreground = "#c0caf5";
    surface = "#24283b";
    overlay = "#414868";

    accent = "#7aa2f7";
    muted = "#565f89";
    urgent = "#f7768e";
    success = "#9ece6a";
    warning = "#e0af68";

    border = "#414868";
    borderActive = "#7aa2f7";
  };

  # Opacity as a 0-1 float; consumers format into their own hex-alpha or
  # rgba() syntax as needed (Hyprland wants hex alpha appended to hex RGB,
  # QML wants Qt.rgba() or an "#AARRGGBB" string).
  opacity = {
    borderActive = 0.93; # ee/255
    borderInactive = 0.67; # aa/255
    surface = 0.8;
  };

  font = {
    family = "Sans";
    monoFamily = "JetBrainsMono Nerd Font";
    size = 13;
    sizeLarge = 20;
  };

  # Hyprland/Quickshell layout tokens, currently hardcoded in
  # shared/desktop/omarchy/home.nix's settings.config.general/decoration
  # and shell/*.qml radii -- theme-level defaults, overridable per-theme.
  layout = {
    gapsIn = 4;
    gapsOut = 8;
    borderSize = 2;
    rounding = 8;
    barHeight = 32;
  };
}
