# =============================================================================
# Users  --  the human account
# =============================================================================
#
# Note this reads `config.my.username` rather than spelling out a name. See
# modules/options.nix for why.
# =============================================================================
{
  flake.nixosModules.coreUsers =
    { config, pkgs, ... }:
    {
      users.users.${config.my.username} = {
        isNormalUser = true;
        description = config.my.username;

        # fish is also enabled system-wide in core/packages.nix. Both are
        # required: this line picks your login shell, that one installs the
        # shell's system integration.
        shell = pkgs.fish;

        extraGroups = [
          "wheel"           # sudo
          "networkmanager"  # change wifi without a password prompt
          "video"           # screen brightness control
          "audio"
          "input"
          "adbusers"        # android debugging
          "wireshark"       # packet capture without running it as root
        ];
      };

      # Every interactive account on this machine needs a password set with
      # `passwd` after the first boot -- there is deliberately no password in
      # this repo.
      users.mutableUsers = true;
    };
}
