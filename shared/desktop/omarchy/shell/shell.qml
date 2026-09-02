// Milestone 2: minimal Quickshell shell entry point.
// See omarchy-inspired-nixos-plan.md. QML API verified against the pinned
// nixpkgs quickshell source tree (src/wayland/hyprland, src/services/*,
// src/io/process.hpp, src/window) rather than examples of unknown version.
//
// UseQApplication: Quickshell's own comment-based pragma convention (parsed
// in src/launch/launch.cpp before QML parsing even starts -- not a real QML
// `pragma` statement), required for StatusNotifierItem.display()/platform
// menus to work at all. Without it, tray items whose only action is a menu
// (e.g. the NetworkManager applet, Remmina's tray icon) fail every click
// with "Cannot display PlatformMenuEntry as quickshell was not started in
// QApplication mode" -- confirmed live via `qs` before adding this. Pulls
// in the QtWidgets toolkit for the whole session (one-time startup cost),
// a tradeoff the user explicitly accepted.
//@ pragma UseQApplication
import Quickshell

ShellRoot {
    Bar {}
    Notifications {}
    Osd {}
}
