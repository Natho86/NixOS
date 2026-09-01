# Milestone 3: hyprlock + hypridle. Config format verified against upstream
# hyprlock/hypridle wiki docs (content/hypr-ecosystem/user/{hyprlock,hypridle}.md)
# and each project's own README -- both remain on classic hyprlang syntax,
# unlike Hyprland itself which moved to Lua at 0.55 (see Milestone 1 notes).
# programs.hyprlock.enable on the NixOS side (system.nix) auto-configures
# security.pam.services.hyprlock and services.hypridle.enable, so no manual
# PAM wiring is needed here -- confirmed by reading the NixOS module source
# (nixos/modules/programs/wayland/hyprlock.nix).
{ config, pkgs, ... }:

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
          # Tokyo Night
          inner_color = "rgba(26, 27, 38, 0.8)";
          outer_color = "rgba(122, 162, 247, 0.8) rgba(122, 162, 247, 0.2) 45deg";
          font_color = "rgb(192, 202, 251)";
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
          color = "rgba(192, 202, 251, 1.0)";
          font_size = 64;
          font_family = "Sans";
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
