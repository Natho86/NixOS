# Milestone 4/7: Tokyo Night theme tokens. Values are ported verbatim from
# upstream Omarchy's own themes/tokyo-night/colors.toml (github.com/omacom/
# omarchy, MIT licensed, quattro branch), fetched directly via `gh api`, not
# re-derived or guessed -- confirmed byte-for-byte against that file.
#
# This replaces an earlier version of this file whose `colors.foreground`
# used upstream's `bright_foreground` (#c0caf5) as the primary foreground
# instead of upstream's actual `foreground` (#a9b1d6) -- a real divergence
# from upstream discovered when the user reported no visible theme
# difference in Alacritty; upstream's own colors.toml is now the single
# source every consumer (Hyprland, Quickshell, Alacritty, rofi) reads from,
# so this kind of drift can't reappear silently.
{
  name = "tokyo-night";

  colors = {
    background = "#1a1b26";
    foreground = "#a9b1d6";
    surface = "#24283b"; # lighter_background
    overlay = "#414868"; # muted

    accent = "#7aa2f7";
    muted = "#414868";
    urgent = "#f7768e"; # red
    success = "#9ece6a"; # green
    warning = "#e0af68"; # yellow

    border = "#414868"; # muted
    borderActive = "#7aa2f7"; # accent

    selection = "#292e42";
    darkBackground = "#13141c";
    darkerBackground = "#0e0e14";
    darkForeground = "#565f89";
    lightForeground = "#b4bee6";
    brightForeground = "#c0caf5";
  };

  # Full 16-colour ANSI terminal palette, straight from upstream's
  # colors.toml -- needed for Alacritty (and any other terminal-emulator
  # consumer added later), which the semantic `colors` block above alone
  # can't fully drive. Field names match upstream's own colors.toml keys
  # and the alacritty.toml.tpl.sample template's {{ red }}/{{ bright_red }}
  # placeholders exactly, so porting a value here is a straight copy, not
  # a translation.
  ansi = {
    red = "#f7768e";
    yellow = "#e0af68";
    orange = "#eb927b";
    green = "#9ece6a";
    cyan = "#449dab";
    blue = "#7aa2f7";
    magenta = "#ad8ee6";
    brown = "#75493d";

    brightRed = "#ff7a93";
    brightYellow = "#ff9e64";
    brightGreen = "#b9f27c";
    brightCyan = "#0db9d7";
    brightBlue = "#7da6ff";
    brightMagenta = "#bb9af7";
  };

  # Opacity as a 0-1 float; consumers format into their own hex-alpha or
  # rgba() syntax as needed (Hyprland wants hex alpha appended to hex RGB,
  # QML wants Qt.rgba() or an "#AARRGGBB" string).
  opacity = {
    # Exact fractions of the original hand-picked hex alpha bytes
    # (0xee/0xaa), not rounded approximations -- verified via
    # `nix eval` that floor(opacity * 255) reproduces the original
    # hyprland.lua border colours byte-for-byte before this retrofit.
    borderActive = 0.9333333333333333; # 0xee / 255
    borderInactive = 0.6666666666666666; # 0xaa / 255
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
