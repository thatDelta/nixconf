# =============================================================================
# Wallpapers  --  and why the desktop looked flat without them
# =============================================================================
#
# THIS IS THE FIX FOR "THE NOCTALIA THEME LOOKS VERY BASIC".
#
#   noctalia is configured with colorSchemes.useWallpaperColors = true, which
#   means it does not use a fixed palette at all: it runs matugen over your
#   current wallpaper and builds the entire colour scheme from it -- bar,
#   launcher, panels, accents.
#
#   ~/Pictures/Wallpapers did not exist. With no wallpaper there is nothing to
#   derive colours from, so noctalia fell back to its plain built-in scheme.
#   That flat default is what "basic" was; the theme was not misconfigured, it
#   was starved of its input.
#
# WHERE THESE IMAGES COME FROM
#   The SilentSDDM flake input -- already a dependency for your login screen
#   theme, so this costs nothing extra and adds no binaries to this repo.
#
# ADDING YOUR OWN
#   The directory itself is a normal writable directory; only these seed files
#   are read-only symlinks. Drop any image into ~/Pictures/Wallpapers and it
#   shows up in the picker (Ctrl+Mod+T).
# =============================================================================
{ inputs, ... }:
let
  seed = "${inputs.silentSDDM}/backgrounds";
in
{
  home.file = {
    "Pictures/Wallpapers/rei.png".source = "${seed}/rei.png";
    "Pictures/Wallpapers/silvia.png".source = "${seed}/silvia.png";
    "Pictures/Wallpapers/ken.png".source = "${seed}/ken.png";
    "Pictures/Wallpapers/mountain.jpg".source = "${seed}/mountain.jpg";
    "Pictures/Wallpapers/smoky.jpg".source = "${seed}/smoky.jpg";
  };
}
