# Milestone 1: Hyprland foundation (Home Manager side).
# Keybindings, input, monitor and initial appearance. Package ownership
# stays with NixOS (programs.hyprland.enable in system.nix), so package
# is set to null here per the Home Manager module's own guidance.
{ config, pkgs, lib, ... }:

let
  # Milestone 4: shell/ + generated Theme.qml/qmldir combined into one
  # derivation -- see theme.nix for why this can't be two separate
  # Home Manager sources under the same ~/.config/quickshell/omarchy path.
  omarchyShell = import ./theme.nix { inherit pkgs lib; };

  omarchyTheme = (import ./themes/default.nix).theme;

  # Hyprland's config wants "rgba(RRGGBBAA)" (hex, no leading #, alpha as a
  # two-digit hex byte). themes/*.nix stores colours as "#RRGGBB" and
  # opacity as a 0-1 float, matching QML's `color`/Qt.rgba conventions
  # instead -- this converts between the two so both consumers can read
  # the same theme source.
  hexNoHash = color: lib.removePrefix "#" color;
  # lib.toHexString does not zero-pad (e.g. 12 -> "C", not "0C") and
  # returns uppercase -- confirmed live via `nix eval`. Both would produce
  # a malformed rgba() string or an inconsistent case versus the rest of
  # the hex literals already in this file, so pad and lowercase explicitly.
  toAlphaHex = opacity:
    lib.toLower (lib.fixedWidthString 2 "0" (lib.toHexString (builtins.floor (opacity * 255))));
  hyprlandRgba = color: opacity: "rgba(${hexNoHash color}${toAlphaHex opacity})";
in
{
  # Milestone 2: Quickshell bar. Config directory structure and
  # systemd.target default verified against the pinned Home Manager
  # quickshell module source (modules/programs/quickshell.nix) --
  # wayland.systemd.target defaults to "graphical-session.target", which
  # UWSM activates itself when Hyprland starts (confirmed in Milestone 1:
  # programs.uwsm binds the compositor into graphical-session-pre.target,
  # graphical-session.target, xdg-desktop-autostart.target), so no target
  # override is needed even though wayland.windowManager.hyprland.systemd.enable
  # is false here (UWSM, not Home Manager, owns that integration).
  programs.quickshell = {
    enable = true;
    configs.omarchy = omarchyShell.quickshellConfigDir;
    activeConfig = "omarchy";
    systemd.enable = true;
  };

  wayland.windowManager.hyprland = {
    enable = true;
    package = null;
    portalPackage = null;
    systemd.enable = false; # UWSM owns session/systemd integration, not HM.
    configType = "lua"; # Hyprland >=0.55 deprecated hyprlang in favour of Lua; we're on 0.56.2

    # Declarative config (matches hl.config({...}) / hl.monitor({...}) /
    # hl.animation({...}) call shapes). Binds live in extraConfig below,
    # since Lua binds call hl.dsp.* dispatchers directly and are far more
    # readable as real Lua than wrapped in lib.generators.mkLuaInline.
    settings = {
      config = {
        input = {
          kb_layout = "gb";
          follow_mouse = 1;
          touchpad = {
            natural_scroll = true;
            tap_to_click = true;
            disable_while_typing = true;
          };
          sensitivity = 0;
        };

        general = {
          gaps_in = omarchyTheme.layout.gapsIn;
          gaps_out = omarchyTheme.layout.gapsOut;
          border_size = omarchyTheme.layout.borderSize;
          layout = "dwindle";
        };

        decoration = {
          rounding = omarchyTheme.layout.rounding;
          blur = {
            enabled = true;
            size = 4;
            passes = 2;
          };
        };
      };

      # X1 Yoga: single internal display, auto-detected resolution/refresh
      # until hyprctl monitors gives us exact values to pin down.
      monitor = {
        output = "";
        mode = "preferred";
        position = "auto";
        scale = 1;
      };
    };

    # Animations live here rather than in settings.animation: settings.*
    # is always emitted before extraConfig, but hl.animation() requires
    # its named bezier to already be registered via hl.curve(), so the
    # curve registration and the animations that reference it must stay
    # together and in order.
    extraConfig = ''
      hl.curve("easeOutQuint", { type = "bezier", points = { {0.23, 1}, {0.32, 1} } })

      -- 3-finger touchpad swipe to switch workspaces. Replaces the legacy
      -- hyprlang gestures.workspace_swipe boolean, which no longer exists
      -- as a config key under the new Lua gesture system.
      hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

      hl.animation({ leaf = "windows", enabled = true, speed = 4, bezier = "easeOutQuint" })
      hl.animation({ leaf = "windowsOut", enabled = true, speed = 4, bezier = "easeOutQuint", style = "popin 80%" })
      hl.animation({ leaf = "fade", enabled = true, speed = 3, bezier = "easeOutQuint" })
      hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "easeOutQuint" })

      -- Border colours from the Nix theme source (themes/${omarchyTheme.name}.nix),
      -- not hardcoded -- Milestone 4 retrofit. Verified via `nix eval` to
      -- produce byte-identical rgba() values to the original hardcoded
      -- Milestone 1 config before this change.
      hl.config({
        general = {
          ["col.active_border"] = "${hyprlandRgba omarchyTheme.colors.borderActive omarchyTheme.opacity.borderActive}",
          ["col.inactive_border"] = "${hyprlandRgba omarchyTheme.colors.border omarchyTheme.opacity.borderInactive}",
        },
      })

      local mod = "SUPER"
      local terminal = "alacritty"
      local browser = "google-chrome-stable"
      local fileManager = "dolphin"
      -- Milestone 6: apps+commands combined mode (rofi's own combi mode,
      -- configured in launcher.nix), not just drun. Still rofi, not a
      -- native Quickshell launcher -- see launcher.nix for why.
      local menu = "rofi -show combi"
      local windowSwitcher = "rofi -show window"

      hl.bind(mod .. " + RETURN", hl.dsp.exec_cmd(terminal))
      hl.bind(mod .. " + SPACE", hl.dsp.exec_cmd(menu))
      hl.bind(mod .. " + W", hl.dsp.exec_cmd(windowSwitcher))
      hl.bind(mod .. " + SHIFT + Q", hl.dsp.window.close())
      -- Ends the Hyprland session and returns to the greeter, so Plasma/
      -- Qtile/Budgie can be selected. A fuller power/session menu is
      -- Milestone 6 scope; this is the minimum needed to log out at all.
      hl.bind(mod .. " + SHIFT + E", hl.dsp.exit())
      hl.bind(mod .. " + B", hl.dsp.exec_cmd(browser))
      hl.bind(mod .. " + E", hl.dsp.exec_cmd(fileManager))

      hl.bind(mod .. " + F", hl.dsp.window.fullscreen({ action = "toggle" }))
      hl.bind(mod .. " + T", hl.dsp.window.float({ action = "toggle" }))
      hl.bind(mod .. " + TAB", hl.dsp.window.cycle_next())

      -- SUPER+Arrow moves focus (hl.dsp.focus); SUPER+SHIFT+Arrow moves
      -- the window itself (hl.dsp.window.move). These are distinct
      -- dispatchers in the Lua API -- easy to conflate since both take
      -- { direction = }. Moved off vim-style HJKL (used through Milestone
      -- 3) to free SUPER+L for locking the screen -- key names ("Left",
      -- "Right", "Up", "Down") confirmed via xmodmap -pke, same mixed-case
      -- xkb keysym convention as "Print".
      hl.bind(mod .. " + Left", hl.dsp.focus({ direction = "left" }))
      hl.bind(mod .. " + Right", hl.dsp.focus({ direction = "right" }))
      hl.bind(mod .. " + Down", hl.dsp.focus({ direction = "down" }))
      hl.bind(mod .. " + Up", hl.dsp.focus({ direction = "up" }))

      hl.bind(mod .. " + SHIFT + Left", hl.dsp.window.move({ direction = "left" }))
      hl.bind(mod .. " + SHIFT + Right", hl.dsp.window.move({ direction = "right" }))
      hl.bind(mod .. " + SHIFT + Down", hl.dsp.window.move({ direction = "down" }))
      hl.bind(mod .. " + SHIFT + Up", hl.dsp.window.move({ direction = "up" }))

      -- Lock screen. Reuses hypridle's own lock_cmd pattern (pidof guard
      -- avoids double-launching hyprlock if one instance is already
      -- running, e.g. from an idle timeout race).
      hl.bind(mod .. " + L", hl.dsp.exec_cmd("pidof hyprlock || hyprlock"))

      -- SUPER+1..9: switch workspace. SUPER+SHIFT+1..9: move window to
      -- workspace and follow. Workspace focus is hl.dsp.focus({ workspace }),
      -- not a standalone hl.workspace() -- that name doesn't exist.
      for i = 1, 9 do
        local ws = tostring(i)
        hl.bind(mod .. " + " .. ws, hl.dsp.focus({ workspace = i }))
        hl.bind(mod .. " + SHIFT + " .. ws, hl.dsp.window.move({ workspace = ws, follow = true }))
      end

      -- omarchy-volume-*/omarchy-brightness-* (osd-helpers.nix) adjust the
      -- real value then trigger the Quickshell OSD via `qs ipc call`.
      hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("omarchy-volume-up"), { locked = true })
      hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("omarchy-volume-down"), { locked = true })
      hl.bind("XF86AudioMute", hl.dsp.exec_cmd("omarchy-volume-mute-toggle"), { locked = true })
      hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("omarchy-brightness-up"), { locked = true, repeating = true })
      hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("omarchy-brightness-down"), { locked = true, repeating = true })

      -- Media keys (playerctl, MPRIS)
      hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
      hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
      hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

      -- Clipboard history picker (cliphist + rofi -dmenu; cliphist store is
      -- run continuously in the background by shared/desktop/omarchy/clipboard.nix)
      hl.bind(mod .. " + V", hl.dsp.exec_cmd("cliphist list | rofi -dmenu | cliphist decode | wl-copy"))

      -- Audio mixer
      hl.bind(mod .. " + A", hl.dsp.exec_cmd("pavucontrol"))

      -- btop quick-launch overlay. --class distinguishes this instance so
      -- the float/center/size window rule (window-rules.nix) only applies
      -- here, not to regular terminals.
      hl.bind(mod .. " + M", hl.dsp.exec_cmd("alacritty --class alacritty-btop -e btop"))

      -- Screenshots (omarchy-screenshot-* from shared/desktop/omarchy/screenshot.nix).
      -- Key name "Print" confirmed via xmodmap -pke against this keyboard
      -- (xkb keysym, mixed case -- not the all-caps XF86-style names used
      -- for media/brightness keys above).
      hl.bind("Print", hl.dsp.exec_cmd("omarchy-screenshot-region"))
      hl.bind("SHIFT + Print", hl.dsp.exec_cmd("omarchy-screenshot-full"))
      hl.bind(mod .. " + Print", hl.dsp.exec_cmd("omarchy-screenshot-window"))
      hl.bind(mod .. " + SHIFT + Print", hl.dsp.exec_cmd("omarchy-screenshot-output"))
    '';
  };

  home.packages = with pkgs; [
    rofi # temporary placeholder launcher, replaced by Quickshell in Milestone 2
    brightnessctl
    kdePackages.dolphin
    playerctl
    pavucontrol
  ];
}
