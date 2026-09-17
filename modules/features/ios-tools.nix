# =============================================================================
# iOS device tools  --  iloader, and usbmuxd so the machine can even see it
# =============================================================================
#
# iloader (github.com/nab138/iloader) is a GUI sideloader for iOS: it installs
# things like SideStore onto a connected iPhone/iPad over USB.
#
# WHY THIS IS PACKAGED HERE INSTEAD OF PULLED IN AS A FLAKE INPUT
#   iloader ships its own flake.nix that builds the Tauri/Rust app from
#   source, but that flake is missing `outputHashes` for two of its Cargo git
#   dependencies (apple-codesign, isideload) -- without those, Nix has no way
#   to verify the vendored source and the build fails immediately with
#   "No hash was found while vendoring the git dependency". That is a bug in
#   iloader's own flake, not something wrong on this end, and not something
#   fixable from outside their repo (the vendoring step is fixed at eval time
#   inside their flake's build function).
#
#   Rather than fork and maintain a patched copy of someone else's Rust build,
#   this takes the prebuilt Linux AppImage from their GitHub releases instead
#   -- the same binary any non-Nix Linux user would run, unpacked with
#   appimageTools the standard way. It is pinned by version + hash below, so
#   nothing about it changes without a deliberate edit.
#
#   TO UPDATE: bump `version`, then run
#     nix-prefetch-url https://github.com/nab138/iloader/releases/download/v<version>/iloader-linux-amd64.AppImage
#   and paste the resulting hash in below.
#
# WHY usbmuxd MATTERS
#   Apps that talk to an iPhone over USB do not talk to the device directly --
#   they talk to usbmuxd, a background daemon that multiplexes the USB
#   connection. Without it running, iloader opens to an empty device list
#   forever, with no error, because nothing is listening for the phone.
# =============================================================================
{
  perSystem =
    { pkgs, ... }:
    {
      packages.iloader =
        let
          version = "2.3.3";

          src = pkgs.fetchurl {
            url = "https://github.com/nab138/iloader/releases/download/v${version}/iloader-linux-amd64.AppImage";
            hash = "sha256-qehBJZz+wFBl2tMUKN0bJ7bDMh8Q0xDLAxUIKDa4O34=";
          };

          appimageContents = pkgs.appimageTools.extractType2 { inherit src version; pname = "iloader"; };
        in
        pkgs.appimageTools.wrapType2 {
          pname = "iloader";
          inherit version src;

          extraInstallCommands = ''
            install -Dm444 ${appimageContents}/iloader.desktop $out/share/applications/iloader.desktop
            install -Dm444 ${appimageContents}/iloader.png $out/share/icons/hicolor/512x512/apps/iloader.png
          '';
        };
    };

  flake.nixosModules.iosTools = {
    services.usbmuxd.enable = true;
  };
}
