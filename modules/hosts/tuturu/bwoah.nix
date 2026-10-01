# =============================================================================
# bwoah  --  the second drive, mounted at /mnt/bwoah
# =============================================================================
#
# WHY THIS IS MORE THAN ONE fileSystems LINE
#   The drive was formatted by Windows as a "Dynamic Disk" (LDM). Linux sees
#   its big partition (sda3) as an opaque container with no filesystem
#   signature at its start; the real NTFS volume sits at an offset inside it.
#   `ldmtool create all` reads the LDM database and creates a device-mapper
#   device (/dev/mapper/ldm_vol_...) that points at the right offset -- THAT
#   device is mountable.
#
#   So: a oneshot service creates the mapping, and the mount requires it.
#
# WHY AN AUTOMOUNT
#   x-systemd.automount mounts on first access instead of at boot, and
#   `nofail` means a missing/unplugged drive can never hang or fail boot.
#
# TO DISCARD: delete this file and its line in configuration.nix.
# =============================================================================
{ ... }:
{
  flake.nixosModules.tuturuBwoah =
    { pkgs, ... }:
    {
      systemd.services.ldm-bwoah = {
        description = "Map Windows dynamic-disk (LDM) volumes";
        after = [ "dev-sda.device" ];
        bindsTo = [ "dev-sda.device" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.ldmtool}/bin/ldmtool create all";
          ExecStop = "${pkgs.ldmtool}/bin/ldmtool remove all";
        };
      };

      fileSystems."/mnt/bwoah" = {
        device = "/dev/mapper/ldm_vol_DELLTAJUICE-Dg0_Volume1";
        fsType = "ntfs3";
        options = [
          "nofail"
          "x-systemd.automount"
          "x-systemd.requires=ldm-bwoah.service"
          "x-systemd.after=ldm-bwoah.service"
          "uid=1000"   # delta -- so you own the files and can write
          "gid=100"    # users
          "windows_names"
        ];
      };
    };
}
