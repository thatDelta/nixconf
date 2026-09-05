# =============================================================================
# niri  --  the compositor (system side)
# =============================================================================
#
# niri is a scrollable-tiling Wayland compositor: windows sit in one endless
# horizontal strip that you scroll along, rather than being packed into a grid.
#
# This file only turns niri ON. Its configuration -- keybinds, window rules,
# appearance -- is a per-profile concern and lives in the profile's home-manager
# tree:
#     home/yume/niri/
#
# That split is deliberate: a second profile can enable this same module and
# ship a completely different keymap.
# =============================================================================
{
  flake.nixosModules.niri = {

    programs.niri.enable = true;

    # Deliberately NOT setting `programs.niri.package` to a wrapped build.
    #
    # A wrapped niri bakes its config into the nix store and ignores
    # ~/.config/niri/config.kdl. Since this setup generates that file through
    # home-manager, wrapping would mean two competing configs and hours of
    # wondering why an edit did nothing. Stock niri, reading the generated
    # file, keeps exactly one source of truth.

    # niri ships its own entry for the login screen, so the display manager
    # lists it automatically. Do not hand-write a session file --
    # that was how this config previously ended up with two "Niri" entries,
    # one of which launched the bar instead of the compositor.
  };
}
