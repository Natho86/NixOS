# Milestone 4: generates shell/Theme.qml + qmldir from the Nix theme tokens
# (themes/default.nix), then combines them with the hand-written shell/
# directory into one derivation. programs.quickshell.configs.omarchy in
# home.nix must point at this derivation's output (quickshellConfigDir),
# not the bare ./shell path, since Home Manager's xdg.configFile symlinks
# the ENTIRE configs.<name> value as a single unit -- writing separate
# home.file entries under the same ~/.config/quickshell/omarchy path would
# conflict with that whole-directory symlink (confirmed by reading
# modules/programs/quickshell.nix: xdg.configFile."quickshell/${name}".source
# = path, one value per config name).
#
# pragma Singleton + qmldir is Qt's standard mechanism for a directory-local
# shared singleton, not a Quickshell-specific construct.
#
# Milestone 7 note: an earlier version of this file made Theme.qml read a
# runtime-writable state file reactively (FileView + JsonAdapter) so themes
# could switch without a rebuild. That was reverted at the user's explicit
# request after the equivalent live-switching problem turned out to be
# genuinely awkward for Alacritty (Alacritty's own `import` semantics load
# the *importing* file last, so a static fallback file in shared/home.nix
# would always win over a runtime override, not the other way round --
# solvable, but not simple). Rather than have Hyprland/Quickshell live-switch
# while Alacritty/rofi only follow a rebuild, every consumer now follows the
# same simple model: edit `selected` in themes/default.nix, rebuild. See
# theme-switch.nix's removal in the same change for the runtime pieces this
# replaced.
{ pkgs, lib, ... }:

let
  omarchyTheme = import ./themes/default.nix;
  t = omarchyTheme.theme;

  themeQml = ''
    pragma Singleton
    import QtQuick

    // Generated from shared/desktop/omarchy/themes/${t.name}.nix -- do not
    // edit directly, edit the Nix theme file and rebuild instead.
    QtObject {
      readonly property color background: "${t.colors.background}"
      readonly property color foreground: "${t.colors.foreground}"
      readonly property color surface: "${t.colors.surface}"
      readonly property color overlay: "${t.colors.overlay}"

      readonly property color accent: "${t.colors.accent}"
      readonly property color muted: "${t.colors.muted}"
      readonly property color urgent: "${t.colors.urgent}"
      readonly property color success: "${t.colors.success}"
      readonly property color warning: "${t.colors.warning}"

      readonly property color border: "${t.colors.border}"
      readonly property color borderActive: "${t.colors.borderActive}"

      readonly property real opacityBorderActive: ${toString t.opacity.borderActive}
      readonly property real opacityBorderInactive: ${toString t.opacity.borderInactive}
      readonly property real opacitySurface: ${toString t.opacity.surface}

      readonly property string fontFamily: "${t.font.family}"
      readonly property string fontMonoFamily: "${t.font.monoFamily}"
      readonly property int fontSize: ${toString t.font.size}
      readonly property int fontSizeLarge: ${toString t.font.sizeLarge}

      readonly property int gapsIn: ${toString t.layout.gapsIn}
      readonly property int gapsOut: ${toString t.layout.gapsOut}
      readonly property int borderSize: ${toString t.layout.borderSize}
      readonly property int rounding: ${toString t.layout.rounding}
      readonly property int barHeight: ${toString t.layout.barHeight}
    }
  '';

  # qmldir must list every non-singleton QML file used as a type too
  # (Bar, Notifications, Osd), or those implicit directory-local imports
  # break once an explicit qmldir is present -- an explicit qmldir replaces
  # QML's automatic "every .qml file in this directory is importable"
  # behaviour rather than adding to it.
  qmldirContent = ''
    singleton Theme 1.0 Theme.qml
    Bar 1.0 Bar.qml
    Notifications 1.0 Notifications.qml
    Osd 1.0 Osd.qml
  '';

  quickshellConfigDir = pkgs.runCommand "omarchy-quickshell-config" { } ''
    mkdir -p "$out"
    cp -r ${./shell}/* "$out/"
    cp ${pkgs.writeText "Theme.qml" themeQml} "$out/Theme.qml"
    cp ${pkgs.writeText "qmldir" qmldirContent} "$out/qmldir"
  '';
in
{
  inherit quickshellConfigDir;
}
