# =============================================================================
# ipad-display  --  a fake 2360x1640 monitor on the empty HDMI port
# =============================================================================
#
# THE TRICK
#   Nothing is plugged into HDMI-A-1. Two kernel-level settings make the GPU
#   pretend something is:
#     - a custom EDID (a monitor's "ID card") declaring the iPad 10th gen's
#       native 2360x1640@60, built by ./ipad-edid.py;
#     - mode "e" = force this connector ENABLED even with no cable.
#   niri then sees a real second monitor: drag windows onto it, scale it,
#   position it. Sunshine streams ONLY that monitor to Moonlight on the iPad
#   (see the output_name setting) -- so the iPad becomes an extended display,
#   not a mirror.
#
# THE OTHER HALF lives in home/yume/niri/_settings.nix: the HDMI-A-1 output
# block (scale/position) and input.touch/tablet map-to-output, which makes
# taps on the iPad land on the iPad's screen instead of the laptop's.
#
# CAVEAT: if you ever plug a REAL monitor into the HDMI port, it will be
# told it is an iPad. Comment out the import line and rebuild first.
#
# TO DISCARD: delete this file, ipad-edid.py, vbt-*, and its line in configuration.nix (and
# optionally the niri bits above).
# =============================================================================
{ ... }:
{
  flake.nixosModules.tuturuIpadDisplay =
    { pkgs, ... }:
    {
      hardware.display = {
        # The EDID is built by ./ipad-edid.py (see the comment at its top for
        # why the stock hardware.display.edid.modelines generator can't be
        # used: its output made i915 drop every mode). Installed as
        # lib/firmware/edid/ipad.bin, which is where the kernel looks.
        edid.packages = [
          (pkgs.runCommand "ipad-edid" { nativeBuildInputs = [ pkgs.python3 ]; } ''
            mkdir -p $out/lib/firmware/edid
            python3 ${./ipad-edid.py} $out/lib/firmware/edid/ipad.bin
          '')
        ];

        outputs."HDMI-A-1" = {
          edid = "ipad.bin";
          mode = "e"; # force-enable with nothing connected
        };
      };

      # Even with a correct EDID, i915 rejected 2360x1640@60 as CLOCK_HIGH:
      # this laptop's VBT (the GPU's built-in board description) caps the
      # HDMI port at 165 MHz, and the mode needs 255. ./vbt-patch.py clears
      # that one field in a copy of the stock VBT (./vbt-original.bin), and
      # i915.vbt_firmware makes the driver read the copy instead. Every
      # other setting -- the laptop panel included -- is byte-identical.
      #
      # IF THE LAPTOP SCREEN EVER MISBEHAVES after this: pick the previous
      # generation in the boot menu, then remove these two settings.
      hardware.firmware = [
        (pkgs.runCommand "tuturu-vbt" { nativeBuildInputs = [ pkgs.python3 ]; } ''
          mkdir -p $out/lib/firmware/i915
          python3 ${./vbt-patch.py} ${./vbt-original.bin} $out/lib/firmware/i915/tuturu-vbt.bin
        '')
      ];
      boot.kernelParams = [ "i915.vbt_firmware=i915/tuturu-vbt.bin" ];

      # Stream only the fake monitor. With KMS capture Sunshine numbers the
      # displays in DRM order; eDP-1 (laptop) is 0, HDMI-A-1 is 1. If the
      # iPad shows the laptop screen instead, `journalctl --user -u sunshine`
      # lists the detected monitors -- put the right number here.
      services.sunshine.settings.output_name = 1;
    };
}
