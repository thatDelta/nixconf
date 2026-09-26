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

          # /dev/uinput is locked to this group by hardware.uinput.enable
          # (turned on for Sunshine, features/sunshine.nix) -- that option
          # creates the group and the udev rule, but adds no one to it.
          # Sunshine runs as this user via a systemd --user service, and
          # without this it opens fine but every attempt to create a virtual
          # mouse/keyboard/touch device fails silently -- which looks exactly
          # like "Moonlight connects, but input does nothing."
          "uinput"
        ];
      };

      # Every interactive account on this machine needs a password set with
      # `passwd` after the first boot -- there is deliberately no password in
      # this repo.
      users.mutableUsers = true;
    };
}
