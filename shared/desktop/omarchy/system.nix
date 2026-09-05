# Milestone 1: Hyprland foundation (system-level).
# Hyprland session with the Omarchy-inspired desktop profile. See
# omarchy-inspired-nixos-plan.md for the full milestone plan.
#
# Milestone 8: gated behind desktop.omarchy.enable (default.nix) so this
# file is safe to import unconditionally -- it does nothing unless a host
# opts in.
{
  config,
  lib,
  pkgs,
  ...
}:

lib.mkIf config.desktop.omarchy.enable {
  # Hyprland compositor, launched through UWSM for systemd session
  # integration (graphical-session.target, xdg-desktop-autostart.target).
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

  # programs.hyprland's NixOS module always installs BOTH
  # share/wayland-sessions/hyprland.desktop ("Hyprland" -- plain
  # `start-hyprland`, no UWSM) and hyprland-uwsm.desktop
  # ("Hyprland (uwsm-managed)" -- `uwsm start ...`), regardless of withUWSM;
  # withUWSM only enables programs.uwsm, it does not suppress the non-UWSM
  # entry. There is no supported way to remove just one of these two
  # files -- the display manager's session installer copies every
  # .desktop file a listed package ships, and filtering
  # services.displayManager.sessionPackages against its own merged value
  # causes infinite recursion (NixOS's own hyprland module contributes to
  # that same option).
  #
  # ALWAYS SELECT "Hyprland (uwsm-managed)" IN THE GREETER, NOT "Hyprland".
  # Picking the plain entry skips UWSM's systemd/env session setup
  # entirely, causing slow terminal startup and a Hyprland warning that it
  # wasn't launched via hyprland-start.

  services.displayManager.regreet = {
    enable = true;
    # ReGreet's own theme knobs (font/theme/cursor/extraCss) are left at
    # defaults for Milestone 1 and revisited in Milestone 4 once the
    # shared theme tokens exist.
  };

  # greetd's initial_session bypasses the greeter and execs a session command
  # directly on start. This preserves the "boot straight to a session
  # after LUKS unlock" behaviour from hosts/redpill-x1-yoga/configuration.nix.
  #
  # The command MUST match hyprland-uwsm.desktop's own Exec= line
  # (`uwsm start -e -D Hyprland hyprland.desktop`) rather than invoking
  # Hyprland's binary by absolute path. `uwsm start` treats an absolute
  # path as "hardcode mode", a different code path from resolving a
  # Desktop Entry ID, and skips setting XDG_CURRENT_DESKTOP via -D. That
  # mismatch was the actual cause of the auto-login session showing the
  # "not started with hyprland-start" warning and slow terminal startup,
  # even though this path was intended to be UWSM-managed all along.
  #
  # When auto-login is enabled on a host, initial_session logs in to
  # Hyprland directly after the disk is unlocked.
  services.greetd.settings = lib.mkIf config.services.displayManager.autoLogin.enable {
    initial_session = {
      command = "${pkgs.uwsm}/bin/uwsm start -e -D Hyprland hyprland-uwsm.desktop";
      user = config.services.displayManager.autoLogin.user;
    };
  };

  # Milestone 3: enabling this NixOS-level module (not just Home Manager's
  # programs.hyprlock, which only writes the config file) auto-configures
  # security.pam.services.hyprlock and services.hypridle.enable -- confirmed
  # by reading nixos/modules/programs/wayland/hyprlock.nix. No manual PAM
  # setup needed, resolving the gap flagged in Milestone 0.
  programs.hyprlock.enable = true;

  # Quickshell's battery widget reads the laptop battery through UPower.
  services.upower.enable = true;

  # XDG portal routing for the Hyprland session.
  xdg.portal = {
    enable = true;
    config = {
      hyprland = {
        default = [ "hyprland" ];
      };
    };
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  };

}
