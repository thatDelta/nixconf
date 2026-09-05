# =============================================================================
# Security  --  polkit and privilege escalation
# =============================================================================
{
  flake.nixosModules.coreSecurity = {

    # polkit is how an unprivileged graphical app asks for permission to do a
    # privileged thing -- mounting a disk, changing a wifi setting, installing
    # an update. It is the daemon side; the graphical prompt that actually
    # appears on screen is the "polkit agent", started per-profile in
    # modules/features/portals.nix.
    security.polkit.enable = true;

    security.sudo = {
      enable = true;

      # Only members of the wheel group may use sudo at all.
      execWheelOnly = true;

      # Still ask for a password. shin turns this off for convenience; it is
      # left on here because it is the single cheapest thing standing between
      # a stray script and your whole system.
      wheelNeedsPassword = true;
    };
  };
}
