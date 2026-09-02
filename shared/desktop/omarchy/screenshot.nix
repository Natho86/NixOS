# Milestone 3: screenshot commands. grim/slurp composition and hyprctl
# activewindow JSON shape verified live against the running Hyprland
# session, not guessed (activewindow -j returns "at": [x,y], "size": [w,h],
# combined into grim's "-g X,Y WxH" geometry format via jq).
{
  config,
  pkgs,
  lib,
  ...
}:

let
  screenshotDir = "$HOME/Pictures/Screenshots";

  # Shared: save to $screenshotDir with a timestamped name, copy to
  # clipboard, notify. Takes the already-captured PNG bytes on stdin.
  saveAndNotify = pkgs.writeShellScript "omarchy-screenshot-save" ''
    set -euo pipefail
    mkdir -p "${screenshotDir}"
    file="${screenshotDir}/$(date +%Y-%m-%d_%H-%M-%S).png"
    cat > "$file"
    wl-copy < "$file"
    notify-send "Screenshot saved" "$file" -i "$file"
  '';

  screenshotFull = pkgs.writeShellApplication {
    name = "omarchy-screenshot-full";
    runtimeInputs = [
      pkgs.grim
      pkgs.wl-clipboard
      pkgs.libnotify
    ];
    text = ''
      grim - | ${saveAndNotify}
    '';
  };

  screenshotOutput = pkgs.writeShellApplication {
    name = "omarchy-screenshot-output";
    runtimeInputs = [
      pkgs.grim
      pkgs.wl-clipboard
      pkgs.libnotify
      pkgs.hyprland
      pkgs.jq
    ];
    text = ''
      monitor_id=$(hyprctl activewindow -j | jq -r '.monitor')
      output=$(hyprctl monitors -j | jq -r --argjson id "$monitor_id" '.[] | select(.id == $id) | .name')
      grim -o "$output" - | ${saveAndNotify}
    '';
  };

  screenshotWindow = pkgs.writeShellApplication {
    name = "omarchy-screenshot-window";
    runtimeInputs = [
      pkgs.grim
      pkgs.wl-clipboard
      pkgs.libnotify
      pkgs.hyprland
      pkgs.jq
    ];
    text = ''
      geometry=$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')
      grim -g "$geometry" - | ${saveAndNotify}
    '';
  };

  screenshotRegion = pkgs.writeShellApplication {
    name = "omarchy-screenshot-region";
    runtimeInputs = [
      pkgs.grim
      pkgs.slurp
      pkgs.wl-clipboard
      pkgs.libnotify
    ];
    text = ''
      geometry=$(slurp)
      grim -g "$geometry" - | ${saveAndNotify}
    '';
  };
in
{
  home.packages = [
    screenshotFull
    screenshotOutput
    screenshotWindow
    screenshotRegion
    pkgs.wl-clipboard
    pkgs.libnotify
  ];
}
