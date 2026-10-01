# =============================================================================
# ipad-display  --  a fake 2360x1640 monitor on the empty HDMI port
# =============================================================================
#
# THE TRICK
#   Nothing is plugged into HDMI-A-1. Two kernel-level settings make the GPU
#   pretend something is:
#     - a custom EDID (a monitor's "ID card") declaring the iPad 10th gen's
#       native 2360x1640@60, generated from a modeline below;
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
# TO DISCARD: delete this file and its line in configuration.nix (and
# optionally the niri bits above).
# =============================================================================
{ ... }:
{
  flake.nixosModules.tuturuIpadDisplay = {
    hardware.display = {
      # `cvt -r 2360 1640 60` (CVT reduced blanking, 59.98 Hz, 255 MHz pixel
      # clock -- well within this iGPU's HDMI limit). Exposed in the initrd
      # as edid/ipad.bin.
      #
      # ratio=4:3: the generator only knows standard aspect ratios and refuses
      # the iPad's ~1.44. The ratio only feeds a legacy low-res fallback entry
      # (it ends up a junk 312x234 mode nobody picks); the real 2360x1640
      # timing is the detailed one, verified with edid-decode.
      edid.modelines."ipad" =
        "255.00  2360 2408 2440 2520  1640 1643 1653 1687 +hsync -vsync ratio=4:3";

      outputs."HDMI-A-1" = {
        edid = "ipad.bin";
        mode = "e"; # force-enable with nothing connected
      };
    };

    # Stream only the fake monitor. With KMS capture Sunshine numbers the
    # displays in DRM order; eDP-1 (laptop) is 0, HDMI-A-1 is 1. If the
    # iPad shows the laptop screen instead, `journalctl --user -u sunshine`
    # lists the detected monitors -- put the right number here.
    services.sunshine.settings.output_name = 1;
  };
}
