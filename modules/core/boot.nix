# =============================================================================
# Boot  --  bootloader and kernel
# =============================================================================
{
  flake.nixosModules.coreBoot =
    { pkgs, ... }:
    {
      boot.loader = {
        # systemd-boot is the simple UEFI bootloader. It lists your NixOS
        # generations at startup, which is how you roll back a bad rebuild:
        # pick an older entry from this menu.
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;

        # Keep the boot menu readable. Without a limit, every single rebuild
        # adds an entry and the list grows forever.
        systemd-boot.configurationLimit = 20;
      };

      # Newest stable kernel. Worth having on recent laptop hardware for
      # working wifi/graphics drivers.
      boot.kernelPackages = pkgs.linuxPackages_latest;

      # Compress a quarter of RAM and use it as swap. Cheap insurance against
      # running out of memory during a big nix build.
      zramSwap = {
        enable = true;
        algorithm = "zstd";
        memoryPercent = 25;
      };
    };
}
