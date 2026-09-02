# Milestone 7: Hackerman theme tokens, ported verbatim from upstream
# Omarchy's own themes/hackerman/colors.toml (github.com/omacom/omarchy,
# MIT licensed, quattro branch), fetched directly via `gh api`, not
# invented -- confirmed byte-for-byte against that file. Replaces the
# earlier Catppuccin second theme per explicit user request, to focus on
# the two real upstream Omarchy themes the user actually wants nailed
# down: Tokyo Night and Hackerman.
{
  name = "hackerman";

  colors = {
    background = "#0B0C16";
    foreground = "#ddf7ff";
    surface = "#151828"; # lighter_background
    overlay = "#2d3450"; # muted

    accent = "#82FB9C";
    muted = "#2d3450";
    urgent = "#50f872"; # red (Hackerman's "red" is green-tinted by design)
    success = "#4fe88f"; # green
    warning = "#50f7d4"; # yellow

    border = "#2d3450"; # muted
    borderActive = "#82FB9C"; # accent

    selection = "#1f253a";
    darkBackground = "#080910";
    darkerBackground = "#06060c";
    darkForeground = "#6a6e95";
    lightForeground = "#b5c5db";
    brightForeground = "#ddf7ff";
  };

  # Full 16-colour ANSI terminal palette, straight from upstream's
  # colors.toml -- same field shape as themes/tokyo-night.nix (see that
  # file's comment for why).
  ansi = {
    red = "#50f872";
    yellow = "#50f7d4";
    orange = "#50f7a3";
    green = "#4fe88f";
    cyan = "#7cf8f7";
    blue = "#829dd4";
    magenta = "#86a7df";
    brown = "#287b51";

    brightRed = "#85ff9d";
    brightYellow = "#a4ffec";
    brightGreen = "#9cf7c2";
    brightCyan = "#d1fffe";
    brightBlue = "#c4d2ed";
    brightMagenta = "#cddbf4";
  };

  # Upstream's hyprland_active_border for Hackerman is a genuine two-stop
  # gradient ("rgba(26a269ee) rgba(2ec27eee) 45deg"), unlike Tokyo Night's
  # flat colour -- not replicated here since this repo's Hyprland/theme
  # pipeline (hyprlandRgba in home.nix, omarchy-theme-reload-hyprland in
  # theme-switch.nix) only handles a single active/inactive border colour
  # each, not gradients. Using accent as a flat colour instead is a
  # deliberate simplification, not a missed value.
  opacity = {
    borderActive = 0.9333333333333333; # 0xee / 255, matching tokyo-night's convention
    borderInactive = 0.6666666666666666; # 0xaa / 255
    surface = 0.8;
  };

  font = {
    family = "Sans";
    monoFamily = "JetBrainsMono Nerd Font";
    size = 13;
    sizeLarge = 20;
  };

  layout = {
    gapsIn = 4;
    gapsOut = 8;
    borderSize = 2;
    rounding = 8;
    barHeight = 32;
  };
}
