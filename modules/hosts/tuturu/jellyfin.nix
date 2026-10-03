# =============================================================================
# jellyfin  --  a local library for the anime on the bwoah drive
# =============================================================================
#
# WHAT THIS IS FOR
#   Not a "media server" in the share-with-everyone sense: it is the library
#   that scans /mnt/bwoah/Videos, finds the shows and movies, puts episodes
#   in order, remembers what you've watched, and lets the player skip intros.
#   You watch it in the Jellyfin desktop app (home/yume/packages.nix), which
#   niri opens on the iPad monitor (home/yume/niri/_rules.nix), and that
#   reaches the iPad through Sunshine/Moonlight like everything else.
#
#   The server only listens on this machine plus the iPad hotspot (ap0 is
#   trusted in ipad-hotspot.nix). Nothing is opened to other networks.
#
# THEME: Abyss (aumgupta.github.io/abyss-jellyfin) -- dark, frosted glass.
#   It has two halves:
#     - the CSS, pasted once into the dashboard (step 4 below);
#     - "Spotlight", a big Continue-Watching banner on the home screen. Its
#       installer edits jellyfin-web's index.html in place, which is
#       impossible here (the Nix store is read-only), so the same edit is
#       done at build time: `abyssWeb` below is jellyfin-web plus
#       Spotlight's three files and its one <script> tag.
#
# WHAT IS NOT IN NIX (set once in the web UI, kept in /var/lib/jellyfin)
#   Jellyfin keeps libraries, users, plugins and settings in its own
#   database. NixOS has no options for them, so set them up by hand once:
#
#   1. Open http://localhost:8096 and run the setup wizard: make a user and
#      add two libraries:
#        "Anime"   content type Shows   folder /mnt/bwoah/Videos/Anime
#        "Movies"  content type Movies  folder /mnt/bwoah/Videos/Movies
#      Each show is a folder of episodes; each movie is a file or a folder.
#
#   2. Plugins. Dashboard -> Plugins -> Repositories -> "+", add:
#        Intro Skipper     https://intro-skipper.org/manifest.json
#      Then Catalog -> install "Intro Skipper", restart Jellyfin (Dashboard
#      -> Restart). It fingerprints episode audio to find the opening and
#      ending of each episode; the first scan takes a while.
#      From the default repository, "AniList" gives better anime metadata
#      than the stock TMDb lookup.
#
#   3. Skipping. User menu -> Settings -> Playback -> Media segments: set
#      Intro/Outro to "Ask to skip" (a button) or "Skip" (automatic).
#      "Next episode" and the up-next popup are built in.
#
#   4. Abyss. Dashboard -> General -> Custom CSS, paste:
#        @import url('https://cdn.jsdelivr.net/gh/AumGupta/abyss-jellyfin@main/abyss.css');
#      Then User menu -> Settings -> Display -> Theme: Dark (Abyss needs
#      it), and Settings -> Home, section order: Continue Watching, Next Up,
#      My Media, Recently Added.
#
# TO DISCARD: delete this file and its line in configuration.nix, then
#   sudo rm -rf /var/lib/jellyfin /var/cache/jellyfin
# =============================================================================
{ ... }:
{
  flake.nixosModules.tuturuJellyfin =
    { pkgs, ... }:
    let
      # Pinned to one commit so a rebuild never changes the theme by
      # surprise. TO UPDATE: put a newer commit here; the rebuild then
      # fails with the right hashes for the three files -- paste them in.
      abyssRev = "ac84b8840ce7eb7521760bc0d1ed2a045616a0be";
      spotlight = file: hash:
        pkgs.fetchurl {
          url = "https://raw.githubusercontent.com/AumGupta/abyss-jellyfin/${abyssRev}/scripts/spotlight/${file}";
          inherit hash;
        };

      # jellyfin-web plus Spotlight, with the <script> tag added to index.html.
      # Real copies, not symlinks: Jellyfin sends a symlink's OWN size (~100
      # bytes) as the file length, so every linked file arrived truncated and
      # the web UI loaded as a blank page.
      abyssWeb = pkgs.runCommand "jellyfin-web-abyss" { } ''
        web=${pkgs.jellyfin-web}/share/jellyfin-web
        cp -r $web $out
        chmod -R u+w $out
        mkdir $out/ui
        sed 's|</body>|<script src="ui/spotlight-loader.js" data-abyss-spotlight></script></body>|' \
          $web/index.html > $out/index.html
        cp ${spotlight "spotlight.html" "sha256-Y0Mdyt8BfiVAIvb4fm3LMhKbBtQCveIFLiGKQKgvVEk="} $out/ui/spotlight.html
        cp ${spotlight "spotlight.css" "sha256-8ffaCcoc7OBiIhEV0V5wAt6nFIpl3fcqs8XpWutPre0="} $out/ui/spotlight.css
        cp ${spotlight "spotlight-loader.js" "sha256-gnSXre8/guO3Hj3Q/ef72xd2G833JEVlu8kD8vXsG24="} $out/ui/spotlight-loader.js
      '';

      # The jellyfin package bakes its web directory into bin/jellyfin (a
      # shell wrapper). Rather than rebuilding Jellyfin from source to change
      # that, copy the wrapper and point it at abyssWeb; the rest is links.
      # mainProgram: the NixOS module starts `lib.getExe package`, which
      # otherwise guesses the binary from this derivation's name.
      jellyfinAbyss = pkgs.runCommand "jellyfin-abyss-${pkgs.jellyfin.version}" {
        meta.mainProgram = "jellyfin";
      } ''
        mkdir $out
        ln -s ${pkgs.jellyfin}/* $out/
        rm $out/bin
        mkdir $out/bin
        sed 's|${pkgs.jellyfin-web}/share/jellyfin-web|${abyssWeb}|' \
          ${pkgs.jellyfin}/bin/jellyfin > $out/bin/jellyfin
        chmod +x $out/bin/jellyfin
        grep -q ${abyssWeb} $out/bin/jellyfin # fail loudly if the wrapper changed shape
      '';
    in
    {
      services.jellyfin = {
        enable = true;
        package = jellyfinAbyss;

        # Transcoding only happens when a client can't play a file as-is
        # (the desktop app plays everything directly) and for the scrub-bar
        # thumbnails. When it does, do it on the Intel GPU, not the CPU.
        # These settings are only written on the first start; after that
        # the web dashboard (Playback -> Transcoding) owns them.
        hardwareAcceleration = {
          enable = true;
          type = "vaapi";
          device = "/dev/dri/renderD128";
        };
        transcoding = {
          enableHardwareEncoding = true;
          hardwareDecodingCodecs = {
            h264 = true;
            hevc = true;
            hevc10bit = true; # most of the library is 10-bit x265
            vp9 = true;
            av1 = true; # Hellsing Ultimate; Alder Lake decodes AV1 in hardware
          };
          hardwareEncodingCodecs.hevc = true;
        };
      };

      # /mnt/bwoah is mounted as delta with 755 permissions, so the jellyfin
      # user can read it without anything extra. It only reads the videos;
      # its own data (metadata, intro fingerprints) lives in /var/lib/jellyfin.
    };
}
