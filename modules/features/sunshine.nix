# =============================================================================
# Sunshine  --  stream this desktop to an iPad (or anything) via Moonlight
# =============================================================================
#
# Sunshine is a game/screen-streaming HOST. Moonlight is the matching client
# app (free on iOS/iPadOS, and everywhere else). Point Moonlight at this
# machine and it shows your desktop, encoded on the GPU and sent over the
# network -- low latency, built for this, unlike VNC.
#
# THIS IS MIRRORING, NOT EXTENDING
#   The iPad shows a copy of an existing screen. Making it a genuine SECOND
#   monitor (extend) needs a virtual display device (evdi) plus a userspace
#   program that actually registers a display on it -- and no such generic
#   program exists in nixpkgs today; the only real consumer of evdi is
#   DisplayLink's proprietary software, which needs their own USB hardware
#   and won't create a virtual monitor without it. Confirmed evdi's kernel
#   module loads clean on this machine's kernel, if that gap ever closes.
#
# WHY capSysAdmin
#   Sunshine needs a way to grab frames from the compositor. The portal-based
#   route (xdg-desktop-portal + ScreenCast) is built for wlroots compositors
#   and GNOME/KDE; niri is Smithay-based, and whether that path negotiates
#   cleanly here is untested. Direct KMS/DRM capture sidesteps the whole
#   question -- it reads frames straight from the display hardware, the same
#   way regardless of which compositor is running, at the cost of needing
#   CAP_SYS_ADMIN on the binary (handled below via a security wrapper, not by
#   running the whole service as root).
#
# CONFIRMED WORKING ON THIS MACHINE BEFORE THIS WAS WIRED IN
#   `vainfo` lists VAProfileH264Main : VAEntrypointEncSlice once
#   core/graphics.nix's intel-media-driver is present -- hardware H.264
#   encode on the Raptor Lake iGPU, so streaming won't be CPU-bound.
#
# FIRST-TIME SETUP (after rebuilding)
#   1. https://localhost:47990 on this machine -- set the Sunshine web UI
#      username/password (nothing is pre-configured; there is no default).
#   2. Open Moonlight on the iPad, it should find this PC via mDNS
#      (services.avahi, enabled automatically by the module below).
#   3. Moonlight shows a PIN; enter it in the Sunshine web UI to pair.
#
# TO REMOVE THIS FEATURE
#   Delete the one import line in modules/profiles/yume.nix. Nothing else in
#   this repo references it.
# =============================================================================
{
  flake.nixosModules.sunshine = {
    services.sunshine = {
      enable = true;
      capSysAdmin = true;
      openFirewall = true;
    };
  };
}
