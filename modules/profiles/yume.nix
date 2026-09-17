# =============================================================================
# yume  --  the daily-driver desktop profile
# =============================================================================
#
# A PROFILE IS A COMPLETE DESKTOP, CHOSEN AS A UNIT.
#
#   It answers two questions:
#     1. which system features does this desktop need?   -> imports below
#     2. what goes in the user's home directory?         -> home/yume/
#
#   A host picks exactly one profile. Swapping the profile swaps the entire
#   desktop -- compositor, shell, theme, keybinds, applications -- without
#   touching core/ or any other profile.
#
# yume is the shin-flavoured setup: niri + noctalia, dark GTK, WhiteSur icons.
#
# TO CREATE A SECOND PROFILE (say a Hyprland cybersecurity one):
#   1. cp -r home/yume home/kai        and edit it
#   2. copy this file to modules/profiles/kai.nix, rename the module
#      (profileYume -> profileKai) and change the imports it needs
#   3. add a nixosConfiguration for it in modules/hosts/tuturu/default.nix
#   Core stays untouched, and both profiles remain buildable side by side.
# =============================================================================
{ self, ... }:
{
  flake.nixosModules.profileYume =
    { config, ... }:
    {
      imports = with self.nixosModules; [
        niri            # the compositor
        displayManager  # SDDM login screen + SilentSDDM theme
        portals         # file pickers, polkit agent, screen sharing
        homeManager     # the home-manager <-> NixOS bridge
        iosTools        # usbmuxd, so iloader can see a plugged-in iPhone
      ];

      # Recorded so you can confirm which profile a booted generation came
      # from: `nixos-option my.profile`
      my.profile = "yume";

      # The home side of this profile. `config.my.username` rather than a
      # literal name, so this line does not need editing per machine.
      home-manager.users.${config.my.username} = import ../../home/yume;
    };
}
