# Milestone 4: theme selector. Not a NixOS option (this repo's omarchy
# module is imported directly into flake.nix rather than exposing a
# desktop.omarchy.enable/options tree per the plan's §4 illustrative
# interface -- introducing that now would be a bigger change than this
# milestone calls for). Change `selected` below to switch themes; every
# consumer imports `theme` from this file rather than hardcoding colours.
let
  themes = {
    tokyo-night = import ./tokyo-night.nix;
    catppuccin = import ./catppuccin.nix;
  };

  selected = "tokyo-night";
in
{
  theme = themes.${selected};
  inherit themes selected;
}
