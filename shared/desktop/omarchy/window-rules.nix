# Milestone 5: window rules and Wayland-native env vars. Syntax verified
# against upstream Hyprland wiki (content/configuring/core/rules/window-rules.md,
# content/configuring/core/environment-variables.md): hl.window_rule({
# match = {...}, <effect> = ... }), hl.env("VAR", "value").
#
# Only the pinentry rule below is copied from a confirmed real-world
# example in that doc (the "Fix pinentry losing focus" example uses the
# exact same class regex). File-picker and picture-in-picture rules are
# NOT included here -- the class/title strings those need (e.g. which
# portal backend's file chooser actually shows, or Chrome's PiP window
# title) can't be confirmed without triggering the real dialog on
# hardware, and a wrong guess risks the opposite of the plan's own
# acceptance criterion ("window rules do not unexpectedly capture
# unrelated applications"). Add those once the real class/title is
# captured via `hyprctl activewindow` while the dialog is open.
{ config, pkgs, lib, ... }:

{
  wayland.windowManager.hyprland.extraConfig = ''
    -- Electron/Chromium apps (VSCode, Discord, code-cursor, whatsapp-electron
    -- -- all installed per shared/home.nix) default to XWayland rendering
    -- unless told otherwise, even under a Wayland compositor. hl.env() sets
    -- this only within the Hyprland session itself (confirmed via the
    -- upstream doc's own warning: "avoid putting Wayland-specific env vars
    -- in /etc/environment ... will cause all sessions, including Xorg
    -- ones, to pick them up"), so this is safe even though Plasma/Qtile/
    -- Budgie also run on this host and would break if this leaked globally.
    hl.env("NIXOS_OZONE_WL", "1")

    -- Pinentry (GPG/SSH passphrase prompts) losing focus is a common
    -- Hyprland papercut; this is the documented upstream fix.
    hl.window_rule({
      match = { class = "(pinentry-)(.*)" },
      stay_focused = true,
    })

    -- Float small utility/auth-style dialogs by title pattern rather
    -- than class, since many apps share generic dialog classes but a
    -- distinctive title (file managers' "Open File"/"Save As", GTK/Qt
    -- confirmation dialogs). Conservative: only common, low-risk title
    -- substrings, not full auth-dialog coverage.
    hl.window_rule({
      match = { title = "^(Open File|Save As|Open Folder|Choose Files?)$" },
      float = true,
      center = true,
    })

    -- btop quick-launch overlay (SUPER+M, home.nix): alacritty --class
    -- alacritty-btop distinguishes this specific instance from regular
    -- terminals so only it floats/centers/sizes this way.
    hl.window_rule({
      match = { class = "alacritty-btop" },
      float = true,
      center = true,
      size = { 900, 600 },
    })

    -- Wi-Fi/Bluetooth TUI overlays (SUPER+N / SUPER+SHIFT+N, home.nix).
    hl.window_rule({
      match = { class = "alacritty-impala" },
      float = true,
      center = true,
      size = { 900, 600 },
    })
    hl.window_rule({
      match = { class = "alacritty-bluetui" },
      float = true,
      center = true,
      size = { 900, 600 },
    })

    -- NixOS rebuild trigger overlay (SUPER+SHIFT+R, home.nix). Slightly
    -- taller than the other overlays since rebuild output is verbose.
    hl.window_rule({
      match = { class = "alacritty-rebuild" },
      float = true,
      center = true,
      size = { 1000, 700 },
    })
  '';
}
