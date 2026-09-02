# Milestone 3: helper scripts that adjust volume/brightness then trigger the
# Quickshell OSD via `qs ipc call` (IpcHandler target "osd", see
# shared/desktop/omarchy/shell/Osd.qml). One atomic script per action avoids
# a race between adjusting the value and querying it back for the OSD.
{
  config,
  pkgs,
  lib,
  ...
}:

let
  volumeUp = pkgs.writeShellApplication {
    name = "omarchy-volume-up";
    runtimeInputs = [
      pkgs.pulseaudio
      pkgs.quickshell
    ];
    text = ''
      pactl set-sink-volume @DEFAULT_SINK@ +5%
      pactl set-sink-mute @DEFAULT_SINK@ 0
      pct=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\d+(?=%)' | head -1)
      qs -c omarchy ipc call osd showVolume "$pct"
    '';
  };

  volumeDown = pkgs.writeShellApplication {
    name = "omarchy-volume-down";
    runtimeInputs = [
      pkgs.pulseaudio
      pkgs.quickshell
    ];
    text = ''
      pactl set-sink-volume @DEFAULT_SINK@ -5%
      pct=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\d+(?=%)' | head -1)
      muted=$(pactl get-sink-mute @DEFAULT_SINK@ | grep -q yes && echo 0 || echo "$pct")
      qs -c omarchy ipc call osd showVolume "$muted"
    '';
  };

  volumeMuteToggle = pkgs.writeShellApplication {
    name = "omarchy-volume-mute-toggle";
    runtimeInputs = [
      pkgs.pulseaudio
      pkgs.quickshell
    ];
    text = ''
      pactl set-sink-mute @DEFAULT_SINK@ toggle
      if pactl get-sink-mute @DEFAULT_SINK@ | grep -q yes; then
        qs -c omarchy ipc call osd showVolume "0"
      else
        pct=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\d+(?=%)' | head -1)
        qs -c omarchy ipc call osd showVolume "$pct"
      fi
    '';
  };

  brightnessUp = pkgs.writeShellApplication {
    name = "omarchy-brightness-up";
    runtimeInputs = [
      pkgs.brightnessctl
      pkgs.quickshell
      pkgs.gnugrep
    ];
    text = ''
      brightnessctl set +10%
      pct=$(brightnessctl -m | cut -d, -f4 | tr -d '%')
      qs -c omarchy ipc call osd showBrightness "$pct"
    '';
  };

  brightnessDown = pkgs.writeShellApplication {
    name = "omarchy-brightness-down";
    runtimeInputs = [
      pkgs.brightnessctl
      pkgs.quickshell
      pkgs.gnugrep
    ];
    text = ''
      brightnessctl set 10%-
      pct=$(brightnessctl -m | cut -d, -f4 | tr -d '%')
      qs -c omarchy ipc call osd showBrightness "$pct"
    '';
  };
in
{
  home.packages = [
    volumeUp
    volumeDown
    volumeMuteToggle
    brightnessUp
    brightnessDown
  ];
}
