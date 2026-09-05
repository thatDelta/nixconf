# =============================================================================
# Display manager  --  the login screen (SDDM + the SilentSDDM theme)
# =============================================================================
#
# The display manager is what you see before you log in. It draws the password
# box, lets you pick a session (niri), and then starts that session.
# =============================================================================
{ inputs, ... }:
{
  flake.nixosModules.displayManager =
    { lib, ... }:
    {
      imports = [ inputs.silentSDDM.nixosModules.default ];

      services.displayManager.sddm = {
        enable = true;

        # Run the login screen itself as a Wayland client. Without this SDDM
        # starts an X server just to show a password box.
        wayland.enable = true;
      };

      # The theme comes from the SilentSDDM flake input -- there is no need to
      # keep a copy of the theme's files in this repo.
      programs.silentSDDM = {
        enable = true;
        theme = "rei";
      };

      # X11 is not needed: niri is Wayland and SDDM is running in Wayland mode
      # above. Left off deliberately.
      services.xserver.enable = lib.mkDefault false;
    };
}
