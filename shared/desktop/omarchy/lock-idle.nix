# Milestone 3: hyprlock + hypridle. Config format verified against upstream
# hyprlock/hypridle wiki docs (content/hypr-ecosystem/user/{hyprlock,hypridle}.md)
# and each project's own README -- both remain on classic hyprlang syntax,
# unlike Hyprland itself which moved to Lua at 0.55 (see Milestone 1 notes).
# programs.hyprlock.enable on the NixOS side (system.nix) auto-configures
# security.pam.services.hyprlock and services.hypridle.enable, so no manual
# PAM wiring is needed here -- confirmed by reading the NixOS module source
# (nixos/modules/programs/wayland/hyprlock.nix).
{ config, pkgs, lib, ... }:

let
  omarchyTheme = (import ./themes/default.nix).theme;

  # hyprlock/hyprlang wants "rgba(R, G, B, A)" with A as a 0-1 float, unlike
  # Hyprland's own "rgba(RRGGBBAA)" hex form (see home.nix's hyprlandRgba)
  # -- a third colour format in this repo, all reading the same hex/opacity
  # theme source. lib.toInt does not parse "0x..." hex strings (confirmed
  # live via `nix eval`: "toInt: Could not convert \"0x1a\" to int"), so
  # hex-pair-to-decimal is done via an explicit digit lookup instead.
  hexDigits = lib.stringToCharacters "0123456789abcdef";
  hexDigitValue = d: lib.lists.findFirstIndex (x: x == lib.toLower d) null hexDigits;
  hexByteToInt = pair:
    let
      hi = hexDigitValue (builtins.substring 0 1 pair);
      lo = hexDigitValue (builtins.substring 1 1 pair);
    in hi * 16 + lo;
  hexToRgbDecimal = color:
    let hex = lib.removePrefix "#" color;
    in lib.concatStringsSep ", " (map (n: toString (hexByteToInt (builtins.substring n 2 hex))) [ 0 2 4 ]);
  hyprlockRgba = color: opacity: "rgba(${hexToRgbDecimal color}, ${toString opacity})";
in
{
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        hide_cursor = false;
        grace = 0;
      };

      background = [
        {
          monitor = "";
          path = "screenshot";
          blur_passes = 2;
          blur_size = 4;
        }
      ];

      input-field = [
        {
          monitor = "";
          size = "20%, 5%";
          outline_thickness = 3;
          # Colours from the Nix theme source (Milestone 4 retrofit).
          # font_color was previously hardcoded as rgb(192, 202, 251), a
          # transcription typo -- the theme's actual foreground hex
          # (#c0caf5) is rgb(192, 202, 245). Fixed here rather than
          # preserved, since it was never an intentional value.
          inner_color = hyprlockRgba omarchyTheme.colors.background 0.8;
          outer_color = "${hyprlockRgba omarchyTheme.colors.accent 0.8} ${hyprlockRgba omarchyTheme.colors.accent 0.2} 45deg";
          font_color = "rgb(${hexToRgbDecimal omarchyTheme.colors.foreground})";
          fade_on_empty = true;
          placeholder_text = "<i>Password...</i>";
          fail_text = "<i>$FAIL ($ATTEMPTS)</i>";
          position = "0, -20";
          halign = "center";
          valign = "center";
        }
      ];

      label = [
        {
          monitor = "";
          text = "cmd[update:1000] echo \"$TIME\"";
          color = hyprlockRgba omarchyTheme.colors.foreground 1.0;
          # 64 does not derive cleanly from any existing theme token
          # (sizeLarge is 20, not the clock's actual size) -- kept as the
          # original literal rather than forcing a wrong formula.
          font_size = 64;
          font_family = omarchyTheme.font.family;
          position = "0, 160";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };

  services.hypridle = {
    enable = true;
    settings = {
      general = {
        # loginctl lock-session triggers Hyprlock via the lock PAM/systemd
        # integration hyprlock itself listens for -- avoids starting a
        # second hyprlock instance if one is already running.
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        # hyprctl dispatch now routes through Hyprland's Lua IPC eval, same
        # as Quickshell's Hyprland.dispatch() in Milestone 2 -- the classic
        # "dpms on" dispatcher-string form fails with a Lua syntax error
        # (confirmed by running it live: `[string "return hl.dispatch(dpms on)"]`).
        # Real syntax verified live against the running Hyprland instance;
        # matches the pattern from Hyprland's own upstream hypridle example.
        after_sleep_cmd = ''hyprctl dispatch 'hl.dsp.dpms({ action = "enable" })' '';
      };

      listener = [
        {
          timeout = 300; # 5 min: dim via brightness
          on-timeout = "brightnessctl -s set 10";
          on-resume = "brightnessctl -r";
        }
        {
          timeout = 600; # 10 min: lock
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 630; # 10.5 min: screen off
          on-timeout = ''hyprctl dispatch 'hl.dsp.dpms({ action = "disable" })' '';
          on-resume = ''hyprctl dispatch 'hl.dsp.dpms({ action = "enable" })' '';
        }
      ];
    };
  };
}
