# =============================================================================
# Default applications  --  what opens when you click a link or a file
# =============================================================================
#
# A keybind (Mod+B) and a DEFAULT APPLICATION are two different things. The
# keybind is what niri runs when you press the key; the default application is
# what every OTHER program uses when it calls `xdg-open` -- clicking a link in
# your terminal, in Claude Desktop, in a PDF.
#
# Setting only the keybind is how you end up with Mod+B opening firefox while
# links from other apps still open something else.
# =============================================================================
{
  xdg.mimeApps = {
    enable = true;

    defaultApplications = {
      # --- web ------------------------------------------------------------
      "text/html" = [ "firefox.desktop" ];
      "x-scheme-handler/http" = [ "firefox.desktop" ];
      "x-scheme-handler/https" = [ "firefox.desktop" ];
      "x-scheme-handler/about" = [ "firefox.desktop" ];
      "x-scheme-handler/unknown" = [ "firefox.desktop" ];
      "application/xhtml+xml" = [ "firefox.desktop" ];

      # --- files ----------------------------------------------------------
      "inode/directory" = [ "org.kde.dolphin.desktop" ];

      # --- media ----------------------------------------------------------
      "image/png" = [ "swayimg.desktop" ];
      "image/jpeg" = [ "swayimg.desktop" ];
      "image/gif" = [ "swayimg.desktop" ];
      "image/webp" = [ "swayimg.desktop" ];
      "video/mp4" = [ "mpv.desktop" ];
      "video/x-matroska" = [ "mpv.desktop" ];
      "audio/mpeg" = [ "mpv.desktop" ];
      "audio/flac" = [ "mpv.desktop" ];
    };
  };

  # Tell command-line tools the same thing. Some programs read $BROWSER
  # instead of asking the xdg database.
  home.sessionVariables.BROWSER = "firefox";
}
