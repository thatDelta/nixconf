# =============================================================================
# Core packages  --  tools every profile gets
# =============================================================================
#
# THE RULE FOR THIS FILE
#   Put something here if you would be annoyed to find it missing on ANY
#   machine you build from this repo -- the cybersecurity profile, a server,
#   a rescue boot.
#
#   Anything tied to a particular desktop or theme (icon themes, bars,
#   compositor helpers) belongs to that profile instead:
#       home/yume/packages.nix
#
# SYSTEM vs USER packages
#   These are installed system-wide, available to every user including root
#   and to scripts running before you log in. Day-to-day applications are
#   better installed per-user through home-manager, which is why this list is
#   deliberately short.
# =============================================================================
{
  flake.nixosModules.corePackages =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        # --- the absolute minimum to repair a broken system -----------------
        git         # you need this to even fetch this config
        vim         # a guaranteed editor; neovim is set up per-profile
        wget
        curl
	opencode-desktop

        # --- everyday shell ------------------------------------------------
        fastfetch
        killall
        file
        jq          # read JSON on the command line
        unzip
        zip
        tree

        # --- hardware inspection, for when something does not work ---------
        pciutils    # lspci
        usbutils    # lsusb
      ];

      # Enable the shells system-wide. This installs completions and the
      # /etc/shells entry -- the per-user choice of login shell is in
      # core/users.nix.
      programs.fish.enable = true;
      services.tailscale.enable = true;
    };
}
