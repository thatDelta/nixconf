# =============================================================================
# my.*  --  the handful of knobs this config exposes
# =============================================================================
#
# WHY THIS FILE EXISTS
#   Before this, the username "delta" was typed literally inside several
#   modules. That meant a module could only ever work for one person on one
#   machine, and swapping profiles meant editing every file that mentioned it.
#
#   Now modules ask for `config.my.username` instead. Set it once (in the host
#   file) and everything downstream follows.
#
# HOW TO USE IT
#   Anywhere inside a NixOS module you can read these:
#       { config, ... }: {
#         home-manager.users.${config.my.username} = ...;
#       }
#
# WHERE IT IS SET
#   modules/hosts/tuturu/configuration.nix
# =============================================================================
{
  flake.nixosModules.options =
    { lib, ... }:
    {
      options.my = {

        username = lib.mkOption {
          type = lib.types.str;
          example = "delta";
          description = ''
            Login name of the primary human user of this machine.
            Used for the user account, the home-manager scope, and any
            path that needs to point at the home directory.
          '';
        };

        profile = lib.mkOption {
          type = lib.types.str;
          example = "yume";
          description = ''
            Name of the desktop profile currently active on this machine.

            Each profile (modules/profiles/*.nix) sets this to its own name.
            It is informational: it lets you confirm which profile a running
            generation was built from, with

                nixos-option my.profile

            rather than guessing from what is on screen.
          '';
        };

      };
    };
}
