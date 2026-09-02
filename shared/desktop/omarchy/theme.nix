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
# Milestone 7: Theme.qml no longer embeds literal colour/opacity/font/
# layout values from Nix. Instead it's a FileView (Quickshell's file-
# reading QML type, confirmed against the pinned source's fileview.hpp)
# pointed at ~/.local/state/omarchy/theme.json with watchChanges = true,
# using a JsonAdapter (jsonadapter.hpp) to bind that JSON reactively into
# QML properties -- syntax (nested `property JsonObject foo: JsonObject
# { property string bar: ... }`) copied directly from that file's own
# worked doc-comment example, not guessed. theme-switch.nix's
# omarchy-theme-set writes the new theme's full resolved JSON to that
# same path, and Quickshell picks it up automatically with no explicit
# reload/IPC call needed (unlike Hyprland, which has no equivalent
# "watch this file" primitive and needs `hyprctl eval` pushed instead).
#
# Every property below is still exposed flat on Theme (Theme.background,
# Theme.rounding, ...) via a thin alias layer, matching the JSON's own
# nested shape (colors.background, layout.rounding, ...) underneath --
# this keeps Bar.qml/Notifications.qml/Osd.qml untouched; they already
# only ever read Theme.<flatName>.
{ pkgs, lib, config, ... }:

let
  omarchyTheme = import ./themes/default.nix;
  t = omarchyTheme.theme;

  # Same path theme-switch.nix's omarchy-theme-set writes to -- built from
  # config.xdg.stateHome (not a literal $HOME string) so QML gets a real
  # absolute path with no shell-expansion step, since FileView.path is a
  # plain string/URL, not a shell command line (confirmed against
  # fileview.hpp: no mention of tilde/env-var expansion, only
  # Qt.resolvedUrl() for relative-to-this-file paths in its own example).
  stateFile = "${config.xdg.stateHome}/omarchy/theme.json";

  themeQml = ''
    pragma Singleton
    import Quickshell.Io
    import QtQuick

    // Reads ~/.local/state/omarchy/theme.json reactively (Milestone 7).
    // Nix-time theme fallback values below (from
    // shared/desktop/omarchy/themes/${t.name}.nix) only matter before the
    // state file exists (e.g. between install and Home Manager's first
    // activation, which seeds it) -- theme-switch.nix's home.activation
    // guarantees the file exists after that, so these are a cold-start
    // safety net, not the steady-state source of truth.
    //
    // A QML document has exactly one root object; the singleton itself
    // is that QtObject, with the FileView nested as a normal child
    // property. The flat properties below read through
    // fileView.adapter.<group>.<name> -- a plain qualified property
    // chain, not an `id` reference into a sibling component instance.
    // An `id` on the JsonAdapter (originally `id: fileData`, referenced
    // directly from the flat properties) looked simpler but qmllint
    // flagged every such reference as "Unqualified access" even after
    // adding "pragma ComponentBehavior: Bound" (which fixes the opposite
    // direction -- an outer id read from inside a nested delegate, not
    // this one) -- confirmed live with `qmllint`, not assumed, and fixed
    // by going through the already-declared `fileView` property instead.
    QtObject {
      readonly property FileView fileView: FileView {
        path: "${stateFile}"

        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
          property JsonObject colors: JsonObject {
            property string background: "${t.colors.background}"
            property string foreground: "${t.colors.foreground}"
            property string surface: "${t.colors.surface}"
            property string overlay: "${t.colors.overlay}"
            property string accent: "${t.colors.accent}"
            property string muted: "${t.colors.muted}"
            property string urgent: "${t.colors.urgent}"
            property string success: "${t.colors.success}"
            property string warning: "${t.colors.warning}"
            property string border: "${t.colors.border}"
            property string borderActive: "${t.colors.borderActive}"
          }

          property JsonObject opacity: JsonObject {
            property real borderActive: ${toString t.opacity.borderActive}
            property real borderInactive: ${toString t.opacity.borderInactive}
            property real surface: ${toString t.opacity.surface}
          }

          property JsonObject font: JsonObject {
            property string family: "${t.font.family}"
            property string monoFamily: "${t.font.monoFamily}"
            property int size: ${toString t.font.size}
            property int sizeLarge: ${toString t.font.sizeLarge}
          }

          property JsonObject layout: JsonObject {
            property int gapsIn: ${toString t.layout.gapsIn}
            property int gapsOut: ${toString t.layout.gapsOut}
            property int borderSize: ${toString t.layout.borderSize}
            property int rounding: ${toString t.layout.rounding}
            property int barHeight: ${toString t.layout.barHeight}
          }
        }
      }

      readonly property color background: fileView.adapter.colors.background
      readonly property color foreground: fileView.adapter.colors.foreground
      readonly property color surface: fileView.adapter.colors.surface
      readonly property color overlay: fileView.adapter.colors.overlay

      readonly property color accent: fileView.adapter.colors.accent
      readonly property color muted: fileView.adapter.colors.muted
      readonly property color urgent: fileView.adapter.colors.urgent
      readonly property color success: fileView.adapter.colors.success
      readonly property color warning: fileView.adapter.colors.warning

      readonly property color border: fileView.adapter.colors.border
      readonly property color borderActive: fileView.adapter.colors.borderActive

      readonly property real opacityBorderActive: fileView.adapter.opacity.borderActive
      readonly property real opacityBorderInactive: fileView.adapter.opacity.borderInactive
      readonly property real opacitySurface: fileView.adapter.opacity.surface

      readonly property string fontFamily: fileView.adapter.font.family
      readonly property string fontMonoFamily: fileView.adapter.font.monoFamily
      readonly property int fontSize: fileView.adapter.font.size
      readonly property int fontSizeLarge: fileView.adapter.font.sizeLarge

      readonly property int gapsIn: fileView.adapter.layout.gapsIn
      readonly property int gapsOut: fileView.adapter.layout.gapsOut
      readonly property int borderSize: fileView.adapter.layout.borderSize
      readonly property int rounding: fileView.adapter.layout.rounding
      readonly property int barHeight: fileView.adapter.layout.barHeight
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
