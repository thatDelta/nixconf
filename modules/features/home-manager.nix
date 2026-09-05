# =============================================================================
# home-manager  --  the wiring only
# =============================================================================
#
# WHAT HOME-MANAGER IS (read this once, it explains half the repo)
#
#   NixOS manages the SYSTEM: bootloader, drivers, services, users, anything
#   under /etc. It stops at your home directory.
#
#   home-manager manages YOUR HOME the same declarative way: the dotfiles in
#   ~/.config, your per-user packages, your shell setup, your GTK theme.
#   Instead of hand-editing ~/.config/niri/config.kdl, you describe it in Nix
#   and home-manager writes the file for you.
#
#   The payoff is that your dotfiles get the same properties as the rest of
#   NixOS: they are versioned in git, they rebuild identically on a fresh
#   machine, and a bad change is one rollback away.
#
#   The cost is that generated files are READ-ONLY symlinks into /nix/store.
#   You cannot edit ~/.config/niri/config.kdl directly any more -- you edit
#   the Nix source and rebuild. (See WALKTHROUGH.md for the escape hatch when
#   you want to iterate fast on a config without rebuilding each time.)
#
# WHY THIS FILE HAS NO ACTUAL SETTINGS IN IT
#   This module only connects home-manager to NixOS. WHAT goes in your home
#   is profile-specific, so it lives with the profile:
#       modules/profiles/yume.nix  ->  home/yume/
#   That separation is what lets a second profile ship completely different
#   dotfiles without touching this file.
# =============================================================================
{ inputs, ... }:
{
  flake.nixosModules.homeManager =
    { config, ... }:
    {
      imports = [ inputs.home-manager.nixosModules.home-manager ];

      home-manager = {
        # Use the same nixpkgs (and the same allowUnfree setting) as the
        # system, instead of home-manager evaluating a second copy.
        useGlobalPkgs = true;

        # Install user packages into the system profile. Without this they
        # land somewhere systemd user services cannot always see them.
        useUserPackages = true;

        # If home-manager wants to write a file that already exists as a real
        # file, rename the old one to *.backup instead of aborting the whole
        # rebuild. Saves you from a failed switch the first time a program has
        # already written its own config.
        backupFileExtension = "backup";

        # Make flake inputs reachable inside home/ modules, the same way they
        # are in modules/. Without this, `inputs` is undefined over there.
        extraSpecialArgs = { inherit inputs; inherit (config) my; };
      };
    };
}
