# =============================================================================
# Wallpapers  --  and why they decide your whole colour scheme
# =============================================================================
#
# READ THIS IF THE DESKTOP LOOKS FLAT/GREY.
#
#   noctalia is set to colorSchemes.useWallpaperColors = true, which means it
#   does not use a fixed palette at all: it runs matugen over the current
#   wallpaper and derives the entire scheme from it -- bar, launcher, panels,
#   accents, window borders.
#
#   With no wallpaper there is nothing to derive from, and noctalia falls back
#   to its plain built-in scheme. That flat look is not a broken theme, it is
#   a theme with no input.
#
# WHY THIS FILE ONLY MAKES A DIRECTORY
#   shin does not ship wallpapers. Its assets/1.png ... 6.png are 1920x1080
#   SCREENSHOTS used in its README, not wallpapers -- using one would put a
#   picture of someone else's desktop behind your desktop.
#
#   The wallpaper in shin's screenshots is wallhaven-zy1xjw.png, from
#   wallhaven.cc, which is not redistributed in that repo either.
#
#   So: this creates the directory, and the images are yours to choose. Drop
#   any image into ~/Pictures/Wallpapers and press Ctrl+Mod+T to pick it; the
#   colour scheme regenerates from it immediately.
# =============================================================================
{
  # home-manager has no "make an empty directory" option, so this creates a
  # marker file inside it -- the standard trick. The directory itself stays a
  # normal writable directory you can drop images into.
  home.file."Pictures/Wallpapers/.keep".text = ''
    Put wallpapers in this directory.

    noctalia builds its entire colour scheme from whichever one is active
    (Ctrl+Super+T to switch). Until there is at least one image here, the
    desktop uses noctalia's plain fallback palette.
  '';
}
