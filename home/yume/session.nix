# =============================================================================
# Session environment  --  variables that change how apps behave
# =============================================================================
#
# Kept separate from theme.nix (which is about how things LOOK) because these
# change behaviour, and the reasons are worth writing down.
# =============================================================================
{
  home.sessionVariables = {

    # -----------------------------------------------------------------------
    # XDG_CURRENT_DESKTOP -- why this says GNOME when you run niri
    # -----------------------------------------------------------------------
    # Applications branch on this string to decide which desktop integration
    # to use. Almost none of them have heard of niri, so with a bare "niri"
    # they fall back to their lowest-common-denominator behaviour.
    #
    # Two things in particular care:
    #
    #   1. Electron apps (Claude Desktop) choose where to store login tokens
    #      based on this. Seeing GNOME, they use gnome-libsecret -- the
    #      keyring set up in modules/core/keyring.nix -- and your sessions
    #      survive a reboot. Seeing an unknown desktop, they fall back to a
    #      plaintext store, which is both less safe and easier to lose.
    #
    #   2. XDG portals pick their backend from it, which is what makes file
    #      pickers and screen sharing work.
    #
    # The "niri:" prefix is kept first so anything that DOES know about niri
    # still recognises it.
    XDG_CURRENT_DESKTOP = "niri:GNOME";
    XDG_SESSION_DESKTOP = "niri";
    XDG_SESSION_TYPE = "wayland";

    # Prefer Wayland over XWayland where an app supports both. XWayland apps
    # look blurry on a scaled display.
    NIXOS_OZONE_WL = "1";   # Electron/Chromium apps run natively on Wayland
    MOZ_ENABLE_WAYLAND = "1";
    SDL_VIDEODRIVER = "wayland";

    # Route file dialogs through the portal rather than GTK's built-in one.
    GTK_USE_PORTAL = "1";
  };
}
