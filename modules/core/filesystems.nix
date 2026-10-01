# =============================================================================
# Filesystem support  --  NTFS, for reading Windows-formatted drives
# =============================================================================
#
# boot.supportedFilesystems pulls in ntfs-3g (the FUSE driver) and wires it up
# as the mount helper for "ntfs" -- so `mount -t ntfs3g` and plain
# `fileSystems.<name>.fsType = "ntfs"` entries both work without installing
# anything by hand.
#
# This only grants the CAPABILITY to mount NTFS drives. Which drive gets
# mounted, and how, is a separate concern -- see WALKTHROUGH.md for why a
# specific external drive is deliberately NOT auto-mounted here yet.
# =============================================================================
{
  flake.nixosModules.coreFilesystems = {
    boot.supportedFilesystems = [ "ntfs" ];
  };
}
