# Milestone 4: theme selector. Not a NixOS option (this repo's omarchy
# module is imported directly into flake.nix rather than exposing a
# desktop.omarchy.enable/options tree per the plan's §4 illustrative
# interface -- introducing that now would be a bigger change than this
# milestone calls for). Change `selected` below to switch themes; every
# consumer imports `theme` from this file rather than hardcoding colours.
#
# Milestone 7 follow-up: narrowed from {tokyo-night, catppuccin} to the
# two real upstream Omarchy themes the user asked to focus on getting
# fully nailed down (rofi, Alacritty, Hyprland, Quickshell all
# consistently themed) -- catppuccin.nix removed rather than kept
# alongside, per explicit user request.
let
  themes = {
    tokyo-night = import ./tokyo-night.nix;
    hackerman = import ./hackerman.nix;
  };

  selected = "tokyo-night";
in
{
  theme = themes.${selected};
  inherit themes selected;
}
