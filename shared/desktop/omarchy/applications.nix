# Milestone 5: default applications and MIME associations. Desktop entry
# IDs and declared MIME types verified against the actual built packages
# (`grep MimeType <pkg>/share/applications/*.desktop`), not guessed --
# every mapping below only uses a MIME type the target application's own
# .desktop file actually lists as supported.
#
# xdg.mimeApps.enable takes over ~/.config/mimeapps.list entirely (the
# generated file is read-only), which already existed as a real,
# hand-accumulated file before this module -- confirmed via `ls -la`
# (a plain regular file, not a symlink) and its content included live
# associations this module didn't create (Signal's URL scheme handlers,
# and x-scheme-handler/claude-cli -> claude-code-url-handler.desktop,
# actively in use). Every pre-existing entry is carried forward below so
# enabling this module doesn't silently drop them. signal.desktop is kept
# even though signal-desktop is currently commented out of home.nix's
# package list -- removing the association wasn't asked for, and pointing
# at an app that isn't installed is harmless (the association simply
# won't resolve to anything until/unless Signal is reinstalled).
#
# force = true on both underlying files: the first `nixos-rebuild switch`
# with this module refused to run ("Existing file ... would be clobbered")
# because Home Manager won't overwrite a file it doesn't already manage.
# Verified every real entry in the pre-existing ~/.config/mimeapps.list is
# reproduced above (diffed programmatically before this change) and that
# ~/.local/share/applications/mimeapps.list is a genuinely empty 0-byte
# file (dated Nov 2025, no content to lose) before forcing either.
{ config, pkgs, ... }:

{
  home.packages = [ pkgs.kdePackages.gwenview ];

  xdg.configFile."mimeapps.list".force = true;
  xdg.dataFile."applications/mimeapps.list".force = true;

  xdg.mimeApps = {
    enable = true;

    defaultApplications = {
      # Pre-existing associations from ~/.config/mimeapps.list, carried
      # forward unchanged.
      "x-scheme-handler/about" = "google-chrome.desktop";
      "x-scheme-handler/unknown" = "google-chrome.desktop";
      "x-scheme-handler/sgnl" = "signal.desktop";
      "x-scheme-handler/signalcaptcha" = "signal.desktop";
      "x-scheme-handler/claude-cli" = "claude-code-url-handler.desktop";

      "inode/directory" = "org.kde.dolphin.desktop";

      # Images -- gwenview's own MimeType= list, verified against the
      # built package.
      "image/avif" = "org.kde.gwenview.desktop";
      "image/gif" = "org.kde.gwenview.desktop";
      "image/heif" = "org.kde.gwenview.desktop";
      "image/jpeg" = "org.kde.gwenview.desktop";
      "image/jxl" = "org.kde.gwenview.desktop";
      "image/png" = "org.kde.gwenview.desktop";
      "image/bmp" = "org.kde.gwenview.desktop";
      "image/webp" = "org.kde.gwenview.desktop";
      "image/tiff" = "org.kde.gwenview.desktop";
      "image/svg+xml" = "org.kde.gwenview.desktop";

      # Video/audio -- a subset of vlc's own MimeType= list.
      "video/mp4" = "vlc.desktop";
      "video/x-msvideo" = "vlc.desktop";
      "video/x-matroska" = "vlc.desktop";
      "video/webm" = "vlc.desktop";
      "video/quicktime" = "vlc.desktop";
      "audio/mpeg" = "vlc.desktop";
      "audio/flac" = "vlc.desktop";
      "audio/ogg" = "vlc.desktop";

      # Web (also PDF -- Chrome's built-in viewer, confirmed in its own
      # MimeType= list; no dedicated PDF reader is installed otherwise)
      "text/html" = "google-chrome.desktop";
      "x-scheme-handler/http" = "google-chrome.desktop";
      "x-scheme-handler/https" = "google-chrome.desktop";
      "application/pdf" = "google-chrome.desktop";

      # Text/code -- opens in VSCode from a file manager double-click;
      # $EDITOR in a terminal remains Neovim (programs.neovim.defaultEditor
      # in shared/home.nix), unrelated to this MIME association.
      "text/plain" = "code.desktop";
    };

    # Pre-existing [Added Associations] entry, carried forward unchanged.
    associations.added = {
      "x-scheme-handler/claude-cli" = "claude-code-url-handler.desktop";
    };
  };
}
