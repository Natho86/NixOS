# Milestone 6: power/session menu. All actions here (suspend/reboot/
# poweroff) use plain `systemctl`, not a privileged wrapper -- NixOS's
# default polkit rules already allow the active local seat's own user to
# invoke org.freedesktop.login1.{suspend,reboot,power-off} without a
# password prompt (the same mechanism a DE's own power menu relies on),
# so no explicit polkit config or sudo is needed here. Nothing in this
# script mutates declaratively managed configuration, matching the
# plan's "no action changes the system in a way that will be silently
# reverted by the next rebuild" acceptance criterion -- it only ever
# calls read-only-to-config runtime commands.
{
  config,
  pkgs,
  lib,
  ...
}:

let
  powerMenu = pkgs.writeShellApplication {
    name = "omarchy-power-menu";
    runtimeInputs = [
      pkgs.rofi
      pkgs.systemd
      pkgs.hyprland
      pkgs.procps
    ];
    text = ''
            options="Lock
      Logout
      Suspend
      Reboot
      Shutdown"

            # rofi -dmenu exits non-zero on cancel (Escape / no selection), same
            # as the dmenu it's a drop-in replacement for. Under `set -o
            # errexit` that would abort the whole script before the case
            # statement below ever runs -- which happens to look like "do
            # nothing" but for the wrong reason (an uncaught failure, not a
            # deliberate no-op). `|| true` makes the intended behaviour explicit
            # instead of relying on errexit's side effect.
            chosen=$(echo "$options" | rofi -dmenu -p "Power" -i) || true

            case "$chosen" in
              Lock)
                pidof hyprlock || hyprlock
                ;;
              Logout)
                hyprctl dispatch 'hl.dsp.exit()'
                ;;
              Suspend)
                systemctl suspend
                ;;
              Reboot)
                systemctl reboot
                ;;
              Shutdown)
                systemctl poweroff
                ;;
              *)
                # Cancelled (Escape, or empty selection) -- do nothing.
                exit 0
                ;;
            esac
    '';
  };
in
{
  home.packages = [ powerMenu ];
}
