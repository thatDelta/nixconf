# =============================================================================
# Desktop plumbing  --  portals, polkit agent, file manager services
# =============================================================================
#
# The unglamorous services that make a bare compositor behave like a desktop.
# Without these, things fail in confusing ways: "Open File" buttons do nothing,
# screen sharing finds no screens, and anything needing admin rights fails
# silently because nothing ever asked you for a password.
# =============================================================================
{
  flake.nixosModules.portals =
    { pkgs, ... }:
    {
      # --- XDG portals -----------------------------------------------------
      # A portal is the bridge between a sandboxed or toolkit-specific app and
      # the desktop. It provides the file picker dialog, screen sharing, and
      # the "open with" handler.
      xdg.portal = {
        enable = true;
        extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

        # niri is not one of the desktops portals know by name, so tell them to
        # fall back to whatever portal is available rather than giving up.
        config.common.default = "*";
      };

      # --- polkit agent ----------------------------------------------------
      # core/security.nix enables the polkit daemon. This is the other half:
      # the agent that actually draws the password dialog on screen. With the
      # daemon but no agent, privileged actions fail without ever prompting.
      systemd.user.services.polkit-gnome = {
        description = "polkit authentication agent";
        wantedBy = [ "graphical-session.target" ];
        after = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        serviceConfig = {
          ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
          Restart = "on-failure";
        };
      };

      # --- file manager plumbing -------------------------------------------
      # Trash support, mounting USB drives, and browsing network shares from a
      # graphical file manager all go through gvfs.
      services.gvfs.enable = true;

      # Creates ~/Downloads, ~/Pictures and friends on first login, which the
      # screenshot path and wallpaper directory both assume exist.
      environment.systemPackages = [ pkgs.xdg-user-dirs ];
    };
}
