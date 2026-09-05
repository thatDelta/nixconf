# =============================================================================
# yume  --  appearance
# =============================================================================
#
# Everything that decides how the desktop LOOKS, in one place: the GTK theme,
# the icon set, the mouse cursor, and the environment variables that tell
# non-GTK applications to follow along.
#
# This is the file to fork when you build a second profile with a different
# look -- nothing here is required for the system to work.
#
# The theme is shin's (linuxmobile/shin): adw-gtk3-dark with WhiteSur icons and
# the Bibata cursor.
# =============================================================================
{ config, pkgs, ... }:
let
  cursorTheme = "Bibata-Original-Ice";
  cursorSize = 20;
  iconTheme = "WhiteSur";

  # Overridden once here and reused below, so the icons in your file manager
  # and the icons in the noctalia dock are guaranteed to be the same build.
  iconPackage = pkgs.whitesur-icon-theme.override {
    boldPanelIcons = true;
    alternativeIcons = true;
  };
in
{
  # --- GTK applications (dolphin, file dialogs, most desktop apps) ---------
  gtk = {
    enable = true;

    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };

    iconTheme = {
      name = iconTheme;
      package = iconPackage;
    };

    cursorTheme = {
      name = cursorTheme;
      package = pkgs.bibata-cursors;
      size = cursorSize;
    };
  };

  # Also set the cursor at the Wayland level, so it is correct over the
  # desktop background and inside applications that do not ask GTK.
  home.pointerCursor = {
    enable = true;
    name = cursorTheme;
    package = pkgs.bibata-cursors;
    size = cursorSize;
    gtk.enable = true;
  };

  # --- Qt applications (dolphin, and noctalia itself) ----------------------
  # "gtk3" makes Qt apps read the GTK theme set above, so you get one
  # consistent look without maintaining a second Qt theme.
  qt = {
    enable = true;
    platformTheme.name = "gtk3";
  };

  # --- environment ---------------------------------------------------------
  home.sessionVariables = {
    # noctalia reads this to find its dock and tray icons. Without it the dock
    # falls back to generic placeholders -- this one variable is the difference
    # between "themed" and "looks unfinished".
    QS_ICON_THEME = iconTheme;

    XCURSOR_THEME = cursorTheme;
    XCURSOR_SIZE = toString cursorSize;
    XDG_ICON_DIR = "${iconPackage}/share/icons/${iconTheme}";

    # Some GTK settings are only readable through gsettings, which needs to be
    # told where the schemas live when it is not running under GNOME.
    GSETTINGS_SCHEMA_DIR =
      "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}/glib-2.0/schemas";

    # Prefer Wayland everywhere rather than falling back to XWayland, which
    # blurs on a scaled display.
    SDL_VIDEODRIVER = "wayland";
    GTK_USE_PORTAL = "1";
  };

  # Bookmarks down the side of GTK file dialogs and dolphin.
  xdg.configFile."gtk-3.0/bookmarks" = {
    force = true;
    text = ''
      file://${config.home.homeDirectory}/Downloads Downloads
      file://${config.home.homeDirectory}/Documents Documents
      file://${config.home.homeDirectory}/Music Music
      file://${config.home.homeDirectory}/Pictures Pictures
      file://${config.home.homeDirectory}/Videos Videos
    '';
  };
}
