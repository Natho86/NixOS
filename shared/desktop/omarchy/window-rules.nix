# Milestone 5: window rules. Syntax verified against upstream Hyprland
# wiki (content/configuring/core/rules/window-rules.md): hl.window_rule({
# match = {...}, <effect> = ... }).
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
  '';
}
