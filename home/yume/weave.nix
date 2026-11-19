# =============================================================================
# Weave  --  mod loader for Lunar Client (and vanilla/Forge/Fabric 1.7-1.21)
# =============================================================================
#
# LOADER vs AGENT
#   "Weave Loader" is the project; the only thing it ships is the AGENT jar.
#   Older releases also had a plain jar meant to be built into a launcher;
#   the agent is the one you use: a Java agent, attached at startup with
#   -javaagent, that patches the game as it loads -- which is how it gets into
#   closed clients like Lunar without touching their files.
#
# USING IT (Lunar Client)
#   Settings -> JVM Arguments, add:
#     -javaagent:/home/delta/.weave/loader.jar
#   Mods go in ~/.weave/mods (Weave Manager installs them there for you).
#
# UPDATING: bump the versions, set hash = "", rebuild, paste the hash Nix prints.
# =============================================================================
{ pkgs, lib, ... }:
let
  agent = pkgs.fetchurl {
    url = "https://github.com/Weave-MC/Weave-Loader/releases/download/1.4.1/Weave-Loader-Agent-1.4.1.jar";
    # matches the .sha256 published with the release
    hash = "sha256-n7ytoS/AMUJuuAYTsCub4x2DrdahFnILfhfkQ50otMg=";
  };

  # GUI for installing/removing Weave mods. Last release is from 2024.
  #
  # Not appimageTools.wrapType2: its runner sets APPIMAGE/APPDIR, and Tauri
  # apps panic on that ("not detected as an AppImage; this might be a security
  # issue"). So: unpack it and run the binary directly in the same FHS env.
  # Its bundled GTK has no Wayland backend -> forced onto X11 (XWayland).
  extracted = pkgs.appimageTools.extract {
    pname = "weave-manager";
    version = "1.0.1";
    src = pkgs.fetchurl {
      url = "https://github.com/Weave-MC/Weave-Manager/releases/download/v1.0.1/weave-manager_1.0.1_amd64.AppImage";
      hash = "sha256-C0mC+yPnNGKQ4adeFwMHB3IWM8RYj0yEOStpDKTesic=";
    };
  };
  manager = pkgs.buildFHSEnv (pkgs.appimageTools.defaultFhsEnvArgs // {
    pname = "weave-manager";
    version = "1.0.1";
    # It finds a running Minecraft by scanning processes; the FHS sandbox's
    # own PID namespace would hide Lunar from it.
    unsharePid = false;
    runScript = pkgs.writeShellScript "weave-manager" ''
      unset APPIMAGE APPDIR
      export GDK_BACKEND=x11 WEBKIT_DISABLE_DMABUF_RENDERER=1
      export LD_LIBRARY_PATH=${extracted}/usr/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
      unset GIO_EXTRA_MODULES   # system gio modules need a newer glib than the bundled one
      cd ${extracted}/usr       # WebKit finds its helper processes relative to here
      exec ${extracted}/usr/bin/weave-manager "$@"
    '';
  });
in
{
  # A stable path for the JVM argument. A plain writable COPY, not a
  # home-manager symlink: Weave Manager checks and rewrites this file itself,
  # and failed with a path error on the read-only link. Re-copied only when it
  # differs from the pinned version (so a manager update gets replaced on the
  # next rebuild -- bump the version here instead).
  home.activation.weaveLoader = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.weave"
    if ! cmp -s ${agent} "$HOME/.weave/loader.jar"; then
      rm -f "$HOME/.weave/loader.jar"
      install -m 644 ${agent} "$HOME/.weave/loader.jar"
    fi
  '';

  home.packages = [
    manager
    (pkgs.makeDesktopItem {
      name = "weave-manager";
      desktopName = "Weave Manager";
      comment = "Install and manage Weave mods";
      exec = "weave-manager";
      icon = "applications-games";
      categories = [ "Game" ];
    })
  ];
}
