# =============================================================================
# iOS device tools  --  iloader, and usbmuxd so the machine can even see it
# =============================================================================
#
# iloader (github.com/nab138/iloader) is a GUI sideloader for iOS: it installs
# things like SideStore onto a connected iPhone/iPad over USB.
#
# THE ONE PATCH ITS FLAKE NEEDS
#   iloader ships a flake, and that is what is used here -- but it does not
#   build as-is. Its flake.nix passes `cargoLock.lockFile` with no
#   `outputHashes`, and the lock file contains two GIT dependencies
#   (apple-codesign, isideload). Nix cannot verify a git dependency without a
#   hash, so the build dies at eval with:
#
#       error: No hash was found while vendoring the git dependency
#              apple-codesign-0.1.0
#
#   That is a bug upstream, not a local problem -- `nix build
#   github:nab138/iloader` fails the same way on a clean machine.
#
#   The fix is small: `cargoDeps` is a plain derivation attribute, so it can
#   be swapped with overrideAttrs. fetchCargoVendor (unlike the older
#   importCargoLock path their flake uses) vendors git dependencies natively
#   under a SINGLE hash, so no per-dependency hashes are needed at all.
#
#   TO UPDATE after bumping the iloader input: the vendor hash below will
#   mismatch. Run the rebuild, and Nix prints the correct hash -- paste it in.
#
# WHY FROM SOURCE RATHER THAN THEIR PREBUILT AppImage
#   The AppImage was tried first and does not work here. It bundles GTK and
#   WebKitGTK built on Ubuntu CI, and its launcher forces GDK_BACKEND=x11;
#   under this machine's Intel Mesa + XWayland that combination aborts on
#   startup with "Could not create default EGL display: EGL_BAD_PARAMETER".
#   Building from source links against this system's own webkitgtk and Mesa,
#   which sidesteps that entire class of problem.
#
#   The cost is a genuinely long first build: ~718 crates, tens of minutes,
#   and there is no binary cache for it. It only rebuilds when the flake
#   input changes.
#
# WHY usbmuxd MATTERS
#   Apps do not talk to a plugged-in iPhone directly -- they talk to usbmuxd,
#   a daemon that multiplexes the USB connection. Without it running, iloader
#   opens to an empty device list forever, with no error, because nothing is
#   listening for the phone.
# =============================================================================
{ inputs, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    {
      packages.iloader = inputs.iloader.packages.${system}.iloader.overrideAttrs (old: {
        cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
          inherit (old) src;

          # The Cargo workspace lives in src-tauri/, not at the flake root.
          # "source" is the directory name fetchCargoVendor unpacks src into.
          sourceRoot = "source/src-tauri";

          hash = "sha256-te7XB/pkM9s94fUJadCtoOvcB/kEN/U1BwQMWcKPglM=";
        };
      });
    };

  flake.nixosModules.iosTools =
    { pkgs, ... }:
    {
      services.usbmuxd.enable = true;

      # Command-line tools for the same usbmuxd that iloader talks to. When
      # iloader sits on "loading devices" these tell you WHERE it broke,
      # which the GUI does not:
      #
      #   idevice_id -l        list connected devices (empty = usbmuxd cannot
      #                        reach the device; pairing/lockdownd problem)
      #   idevicepair validate is this device already trusted?
      #   idevicepair pair     trigger the "Trust This Computer" prompt
      #   ideviceinfo          full device info; fails if not yet trusted
      #
      # And to watch the daemon side while plugging a device in:
      #   journalctl -fu usbmuxd
      environment.systemPackages = [ pkgs.libimobiledevice ];
    };
}
