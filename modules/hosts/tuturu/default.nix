# =============================================================================
# tuturu  --  the buildable system(s) for this machine
# =============================================================================
#
# THIS IS WHERE A PROFILE IS CHOSEN.
#
# Each entry below is a separate system you can build and boot into. They share
# the same hardware and baseline, and differ only in which profile they load.
#
#   sudo nixos-rebuild switch --flake ~/nixconf#tuturu
#
# Because each one is a normal NixOS generation, switching between profiles is
# just a rebuild -- and the bootloader menu still lets you pick the previous
# generation if a profile turns out to be broken.
#
# ADDING A SECOND PROFILE later looks exactly like the block below, with
# `profileYume` swapped for `profileKai` and a different attribute name. Both
# stay buildable, so you can try one without giving up the other.
# =============================================================================
{ self, inputs, ... }:
let
  # Shared by every variant of this host. Only the profile differs.
  mkTuturu = profile: inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.tuturuConfiguration
      profile
    ];
  };
in
{
  flake.nixosConfigurations = {
    # The daily driver: niri + noctalia, shin-flavoured.
    tuturu = mkTuturu self.nixosModules.profileYume;

    # tuturu-kai = mkTuturu self.nixosModules.profileKai;
  };
}
