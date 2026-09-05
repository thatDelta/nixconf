# =============================================================================
# core  --  the baseline every profile gets, no matter what
# =============================================================================
#
# Nothing in here is about looks. This is the "the laptop works" layer:
# it boots, it has network, sound, power management, a user account and a
# handful of tools you would miss immediately if they were gone.
#
# A profile (yume, and whatever you build next) sits ON TOP of this and only
# adds the desktop-specific parts.
#
# Adding a new core module?  Drop the file in modules/core/ and add its name
# to the list below.
# =============================================================================
{ self, ... }:
{
  flake.nixosModules.core = {
    imports = with self.nixosModules; [
      coreBoot
      coreLocale
      coreNetwork
      corePower
      coreAudio
      coreUsers
      coreNix
      corePackages
      coreFonts
      coreSecurity
    ];
  };
}
