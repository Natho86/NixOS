# Milestone 4: GTK icon theme, scoped to match what upstream Omarchy
# itself actually does -- confirmed by reading the real omarchy repo
# (github.com/omacom/omarchy, MIT licensed): it ships no custom GTK CSS
# theme at all, only selects an existing icon theme per-theme (Yaru-magenta
# for its own Tokyo Night theme). Yaru-blue-dark is used here instead of
# Yaru-magenta since blue tonally matches this repo's Tokyo Night accent
# (#7aa2f7) better than Omarchy's own pick.
#
# ~/.config/gtk-{3,4}.0/settings.ini already existed as real, KDE-written
# files (confirmed via `cat` before writing this module) -- every setting
# already present is carried forward explicitly so gtk.enable doesn't
# silently drop them the way a bare `xdg.configFile` conflict would.
# One correction made in the process: the existing gtk-theme-name
# (Catppuccin-Mocha-Standard-Blue-Dark) does not match any theme actually
# present on disk (confirmed via `find /`) -- likely stale from before
# this repo's catppuccin-gtk override existed. Corrected to the real name
# the installed package provides (catppuccin-mocha-blue-standard,
# confirmed by building shared/home.nix's actual catppuccin-gtk.override
# and inspecting share/themes/).
{ config, pkgs, lib, ... }:

{
  # First switch attempt refused with "Existing file ... would be
  # clobbered" for all three of these (confirmed live) -- every setting
  # in each was diffed against the real pre-existing file (see comments
  # above and in each generated section below) before forcing. GTK2 has
  # its own dedicated gtk.gtk2.force option rather than going through
  # home.file directly -- a bare `home.file.".gtkrc-2.0".force = true`
  # conflicts with the target the gtk module already declares internally
  # (confirmed live: "Conflicting managed target files: .gtkrc-2.0").
  xdg.configFile."gtk-3.0/settings.ini".force = true;
  xdg.configFile."gtk-4.0/settings.ini".force = true;

  gtk = {
    enable = true;
    gtk2.force = true;

    theme = {
      name = "catppuccin-mocha-blue-standard";
      package = pkgs.catppuccin-gtk.override {
        accents = [ "blue" ];
        variant = "mocha";
      };
    };

    # GTK4/libadwaita doesn't honour theme names the way GTK3 does; the
    # live gtk-4.0/settings.ini (read before writing this module) already
    # has no gtk-theme-name line at all, confirming the system's actual
    # current behaviour already matches gtk.gtk4.theme = null (the module's
    # own newer default) rather than the stateVersion-gated legacy default
    # of inheriting gtk.theme. Set explicitly rather than relying on the
    # version-gated default, same reasoning as Milestone 1's Hyprland
    # configType fix.
    gtk4.theme = null;

    iconTheme = {
      name = "Yaru-blue-dark";
      package = pkgs.yaru-theme;
    };

    # breeze cursors come from KDE Plasma's own breeze package, already
    # present as a Plasma dependency -- not a separate Home Manager
    # package, same reasoning as package = null elsewhere in this repo
    # for NixOS/system-provided things.
    cursorTheme = {
      name = "breeze_cursors";
      package = null;
      size = 24;
    };

    font = {
      name = "Noto Sans";
      size = 10;
    };

    gtk2.extraConfig = ''
      gtk-enable-animations=1
      gtk-primary-button-warps-slider=1
      gtk-toolbar-style=3
      gtk-menu-images=1
      gtk-button-images=1
      gtk-cursor-blink-time=1000
      gtk-cursor-blink=1
      gtk-sound-theme-name="ocean"
    '';

    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = false;
      gtk-button-images = true;
      gtk-cursor-blink = true;
      gtk-cursor-blink-time = 1000;
      gtk-decoration-layout = "icon:minimize,maximize,close";
      gtk-enable-animations = true;
      gtk-menu-images = true;
      gtk-modules = "colorreload-gtk-module";
      gtk-primary-button-warps-slider = true;
      gtk-sound-theme-name = "ocean";
      gtk-toolbar-style = 3;
      gtk-xft-dpi = 98304;
    };

    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = false;
      gtk-cursor-blink = true;
      gtk-cursor-blink-time = 1000;
      gtk-decoration-layout = "icon:minimize,maximize,close";
      gtk-enable-animations = true;
      gtk-primary-button-warps-slider = true;
      gtk-sound-theme-name = "ocean";
      gtk-xft-dpi = 98304;
    };
  };
}
