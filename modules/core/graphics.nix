# =============================================================================
# Graphics acceleration  --  VAAPI, so video is decoded/encoded on the GPU
# =============================================================================
#
# WHAT THIS FIXES
#   hardware.graphics.enable turns on the base graphics stack (needed for the
#   compositor, and already implicitly relied on elsewhere in this config),
#   but on its own it does NOT install a driver for hardware VIDEO
#   acceleration (VAAPI) -- decoding/encoding video on the GPU instead of the
#   CPU. That was missing here entirely: `vainfo` reported AMD, Nvidia and
#   virtio video drivers present (nixpkgs bundles those unconditionally) but
#   no Intel one, so this machine's iGPU has been doing zero hardware video
#   accel since it was set up.
#
#   That silently costs you in two places:
#     - mpv/Firefox/any video player: software-decoding video that the iGPU
#       could decode almost for free, using far more CPU and battery than
#       necessary.
#     - Sunshine (game/screen streaming, e.g. to an iPad via Moonlight): would
#       have fallen back to software x264 encoding -- much higher CPU load
#       and higher latency than encoding on the GPU.
#
# WHICH DRIVER
#   intel-media-driver ("iHD") is the modern driver, for Broadwell (2014) and
#   newer -- this machine's Raptor Lake-P iGPU is well within that range.
#   intel-vaapi-driver ("i965") is the legacy driver for older chips; not
#   needed here.
#
# VERIFYING IT WORKS
#   vainfo
#   should list VAProfile entries instead of failing to find a driver, and
#   `iHD_drv_video.so` should now be tried and succeed rather than the
#   AMD/Nvidia drivers being tried and failing first.
# =============================================================================
{
  flake.nixosModules.coreGraphics =
    { pkgs, ... }:
    {
      hardware.graphics = {
        enable = true;
        extraPackages = [ pkgs.intel-media-driver ];
      };
    };
}
