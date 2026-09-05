# =============================================================================
# yume  --  home-manager entry point
# =============================================================================
#
# Everything under home/yume/ describes YOUR HOME DIRECTORY for this profile:
# dotfiles, per-user applications, the desktop's appearance. The system side of
# the profile (which compositor to enable, which login screen) lives in
# modules/profiles/yume.nix.
#
# This file is the list of parts. To add something new, drop a file beside
# these and add it to `imports`.
#
# To build a SECOND profile, copy this directory to home/<name>/ and change
# what you like -- nothing here is referenced by name from outside except
# through modules/profiles/<name>.nix.
# =============================================================================
{ ... }:
{
  imports = [
    ./theme.nix      # GTK/Qt theme, icons, cursor
    ./packages.nix   # applications
    ./shell.nix      # fish, starship, atuin
    ./neovim.nix     # neovim + LazyVim
    ./quickshell.nix # the noctalia desktop shell
    ./niri           # compositor config (keybinds, window rules)
  ];

  # -------------------------------------------------------------------------
  # home.stateVersion
  # -------------------------------------------------------------------------
  # This is NOT "the version of home-manager to use". It is the release whose
  # DEFAULTS you want, and it exists so that an upgrade never silently changes
  # behaviour underneath you.
  #
  # Set it to the version you first installed with and then leave it alone --
  # changing it later can move your files around.
  home.stateVersion = "26.05";
}
