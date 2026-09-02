# Milestone 7: controlled live theme switching, without giving up
# reproducibility. The declarative model from Milestone 4 (themes/*.nix
# read at Nix build time) stays exactly as-is and remains the source of
# truth for which themes exist and what the default is -- this module
# adds a *runtime* layer on top, not a replacement.
#
# Design (see omarchy-inspired-nixos-plan.md Milestone 7 for the full
# rationale): the state file at ~/.local/state/omarchy/theme.json holds
# the *fully resolved* active theme (every colour/opacity/font/layout
# value), not just a theme name -- so nothing that reads it at runtime
# (Quickshell, the reload script) needs to re-derive "what is
# tokyo-night" themselves; only the selection command does that lookup,
# against a build-time JSON manifest of every Nix-known theme
# (themesManifest below). This keeps "only Nix-installed themes can be
# selected" (Milestone 7's first acceptance criterion) enforceable in
# one place.
{ config, pkgs, lib, ... }:

let
  themesData = import ./themes/default.nix;

  # Every theme Nix knows about, keyed by name, as plain JSON -- this is
  # the whole "installed set" the selection command validates against.
  # Regenerated on every rebuild, so adding a theme in themes/default.nix
  # makes it selectable at runtime with no other change.
  themesManifest = pkgs.writeText "omarchy-themes-manifest.json"
    (builtins.toJSON themesData.themes);

  defaultThemeName = themesData.selected;

  # Same resolved shape the state file holds -- written once at build
  # time so `omarchy-theme-reset` doesn't need `jq` gymnastics to pull
  # one entry back out of the manifest.
  defaultThemeJson = pkgs.writeText "omarchy-theme-default.json"
    (builtins.toJSON themesData.theme);

  stateDir = "${config.xdg.stateHome}/omarchy";
  stateFile = "${stateDir}/theme.json";

  # Hyprland's Lua-eval live-reconfiguration path (`hyprctl eval`), not
  # `hyprctl keyword` -- confirmed live on hardware this session that
  # keyword fails outright under configType = "lua" ("keyword can't work
  # with non-legacy parsers. Use eval."), and that `hyprctl eval
  # 'hl.config({...})'` does apply instantly. Only the values Hyprland
  # actually themes today (home.nix: general.{gaps_in,gaps_out,
  # border_size}, decoration.rounding, and the two col.*_border keys) are
  # pushed here -- anything else in home.nix's Hyprland config is
  # layout/input, not theme, and untouched by a theme switch.
  hyprlandReload = pkgs.writeShellApplication {
    name = "omarchy-theme-reload-hyprland";
    runtimeInputs = [ pkgs.hyprland pkgs.jq ];
    text = ''
      state="${stateFile}"
      [ -r "$state" ] || { echo "omarchy-theme-reload-hyprland: no state file at $state" >&2; exit 1; }

      gaps_in=$(jq -r '.layout.gapsIn' "$state")
      gaps_out=$(jq -r '.layout.gapsOut' "$state")
      border_size=$(jq -r '.layout.borderSize' "$state")
      rounding=$(jq -r '.layout.rounding' "$state")

      # Same hex-RGB + 0-1-opacity -> "rgba(RRGGBBAA)" conversion as
      # home.nix's hyprlandRgba, reimplemented in awk since this runs at
      # runtime, not Nix eval time. floor(opacity*255), zero-padded lowercase hex.
      to_rgba() {
        hex=$(printf '%s' "$1" | sed 's/^#//')
        awk -v op="$2" -v hex="$hex" 'BEGIN { printf "rgba(%s%02x)", hex, int(op * 255) }'
      }

      border_active_hex=$(jq -r '.colors.borderActive' "$state")
      border_active_op=$(jq -r '.opacity.borderActive' "$state")
      border_hex=$(jq -r '.colors.border' "$state")
      border_inactive_op=$(jq -r '.opacity.borderInactive' "$state")

      active_border=$(to_rgba "$border_active_hex" "$border_active_op")
      inactive_border=$(to_rgba "$border_hex" "$border_inactive_op")

      hyprctl eval "hl.config({ general = { gaps_in = $gaps_in, gaps_out = $gaps_out, border_size = $border_size, [\"col.active_border\"] = \"$active_border\", [\"col.inactive_border\"] = \"$inactive_border\" }, decoration = { rounding = $rounding } })"
    '';
  };

  themeSet = pkgs.writeShellApplication {
    name = "omarchy-theme-set";
    runtimeInputs = [ pkgs.jq pkgs.coreutils hyprlandReload ];
    text = ''
      if [ "$#" -ne 1 ]; then
        echo "usage: omarchy-theme-set <theme-name>" >&2
        exit 1
      fi
      name="$1"
      manifest="${themesManifest}"

      # Only Nix-installed themes can be selected (Milestone 7 acceptance
      # criterion) -- validated against the same manifest the build
      # produced, not a freeform name.
      if ! jq -e --arg n "$name" 'has($n)' "$manifest" >/dev/null; then
        echo "omarchy-theme-set: unknown theme '$name' (not in $manifest)" >&2
        exit 1
      fi

      mkdir -p "${stateDir}"
      tmp=$(mktemp "${stateDir}/.theme.json.XXXXXX")
      # A failed switch must leave the previous theme intact (Milestone 7
      # acceptance criterion): write to a tempfile in the same directory
      # first, only `mv` (atomic rename, same filesystem) over the real
      # state file once the write has fully succeeded.
      trap 'rm -f "$tmp"' EXIT
      jq --arg n "$name" '.[$n]' "$manifest" > "$tmp"
      mv "$tmp" "${stateFile}"
      trap - EXIT

      omarchy-theme-reload-hyprland
      # Quickshell's Theme.qml watches ${stateFile} directly via FileView
      # (watchChanges = true) and updates reactively -- no explicit
      # reload/IPC call needed here, unlike Hyprland.
    '';
  };

  themeReset = pkgs.writeShellApplication {
    name = "omarchy-theme-reset";
    runtimeInputs = [ pkgs.coreutils themeSet ];
    text = ''
      omarchy-theme-set "${defaultThemeName}"
    '';
  };

  themePicker = pkgs.writeShellApplication {
    name = "omarchy-theme-picker";
    runtimeInputs = [ pkgs.rofi pkgs.jq themeSet ];
    text = ''
      manifest="${themesManifest}"
      names=$(jq -r 'keys[]' "$manifest")

      # Same `|| true` reasoning as power-menu.nix: rofi -dmenu exits
      # non-zero on cancel, which would otherwise abort before the
      # cancel case below runs.
      chosen=$(printf '%s\n' "$names" | rofi -dmenu -p "Theme" -i) || true

      [ -n "$chosen" ] && omarchy-theme-set "$chosen"
    '';
  };
in
{
  home.packages = [ themeSet themeReset themePicker hyprlandReload ];

  # Seed the state file with the declarative default ONLY if it doesn't
  # already exist -- must not clobber a runtime `omarchy-theme-set`
  # choice on every rebuild, or "live switching" would only last until
  # the next `nixos-rebuild switch`. Uses the exact `run <cmd>
  # $VERBOSE_ARG ...` / guard idiom confirmed against Home Manager's own
  # modules/misc/xdg/user-dirs.nix (createXdgUserDirectories), not
  # guessed activation-script syntax.
  home.activation.omarchySeedThemeState = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    [[ -e "${stateFile}" ]] || run mkdir -p $VERBOSE_ARG "${stateDir}"
    [[ -e "${stateFile}" ]] || run cp $VERBOSE_ARG "${defaultThemeJson}" "${stateFile}"
  '';
}
