# Milestone 1: Hyprland foundation (system-level).
# Additive session alongside Plasma, Qtile and Budgie. See
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

  # greetd + ReGreet replaces SDDM as the display manager. SDDM is
  # disabled explicitly since services.displayManager.sddm.enable was
  # previously set to true in shared/configuration.nix.
  services.displayManager.sddm.enable = lib.mkForce false;

  services.displayManager.regreet = {
    enable = true;
    # ReGreet's own theme knobs (font/theme/cursor/extraCss) are left at
    # defaults for Milestone 1 and revisited in Milestone 4 once the
    # shared theme tokens exist.
  };

  # Auto-login previously relied on services.displayManager.autoLogin,
  # which SDDM's module read directly. greetd has its own mechanism:
  # initial_session bypasses the greeter and execs a session command
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
  # NOTE: initial_session logs in to Hyprland by default now that this
  # module is enabled. If Plasma should remain the auto-login target
  # instead, override services.greetd.settings.initial_session.command
  # in the host configuration.
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

  # Per-desktop XDG portal routing. Without this, xdg-desktop-portal-hyprland
  # and Plasma's own KDE portal can contend for the same request when both
  # are installed system-wide. Keyed by XDG_CURRENT_DESKTOP, which Hyprland
  # and Plasma set to different values.
  xdg.portal = {
    enable = true;
    config = {
      hyprland = {
        default = [ "hyprland" ];
      };
    };
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  };

  # Milestone 8 top-bar follow-up: stop nm-applet's tray icon from
  # appearing in the Hyprland session's system tray -- the bar's own
  # network popup (SUPER+N or the bar icon) already covers this, and the
  # tray icon was confirmed real (not an artifact of this repo's own
  # config): `programs.nm-applet` isn't enabled anywhere in this repo at
  # all -- it's turned on by NixOS's own Budgie desktop-manager module
  # (nixos/modules/services/desktop-managers/budgie.nix:
  # `programs.nm-applet.enable = config.networking.networkmanager.enable;
  # # Budgie has no Network applet.`), since Budgie genuinely needs it as
  # its own network tray icon. Disabling the service outright would
  # therefore remove Budgie's network icon too, not just Hyprland's --
  # scoped instead via systemd's ConditionEnvironment (a real, standard
  # unit directive, confirmed via `man systemd.unit`) so the unit simply
  # refuses to start when XDG_CURRENT_DESKTOP is "Hyprland" (the exact
  # value confirmed live via `echo $XDG_CURRENT_DESKTOP` in this
  # session), leaving Budgie's own session (a different
  # XDG_CURRENT_DESKTOP value) completely unaffected. This NixOS-level
  # systemd.user.services.nm-applet definition merges additively with
  # the one nm-applet.nix itself sets (same attrset, not a full
  # override), so serviceConfig here only adds a condition rather than
  # replacing nm-applet's own ExecStart/wantedBy.
  # ConditionEnvironment belongs in the [Unit] section, not [Service] --
  # confirmed live: an earlier attempt at serviceConfig.ConditionEnvironment
  # rendered it under [Service], and systemd logged "Unknown key
  # 'ConditionEnvironment' in section [Service], ignoring" (visible via
  # `journalctl --user -u nm-applet.service`), so the condition was
  # silently never applied. unitConfig is the correct NixOS option for
  # [Unit]-section keys (confirmed against a real usage,
  # nixos/modules/system/boot/kexec.nix: `unitConfig.DefaultDependencies
  # = false;`).
  systemd.user.services.nm-applet.unitConfig.ConditionEnvironment = "!XDG_CURRENT_DESKTOP=Hyprland";
}
