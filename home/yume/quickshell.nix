# =============================================================================
# noctalia  --  wrapped with the runtime it needs, then installed
# =============================================================================
#
# WHY THIS WRAPPER EXISTS
#   noctalia is a Quickshell (QML) application. At runtime it shells out to
#   ordinary command-line programs -- brightnessctl to change the backlight,
#   cliphist for clipboard history, cava for the audio visualiser -- and it
#   loads QML modules from Qt.
#
#   On most distributions those are simply "installed somewhere on PATH". Nix
#   has no such global place, so a program that is not told where its
#   dependencies live will start, look, and then quietly do nothing when you
#   press the brightness key.
#
#   The wrapper below fixes that by baking two search paths into the binary:
#     PATH             -> the helper programs it shells out to
#     QML2_IMPORT_PATH -> the Qt modules it imports
#
#   Symptoms of removing this: the bar renders, but brightness/volume/media
#   controls silently fail and the visualiser stays flat.
#
# WHICH noctalia IS THIS?
#   `myNoctalia` from modules/features/noctalia.nix -- the build with your
#   noctalia.json settings already baked in. Wrapping the plain package here
#   instead would silently throw those settings away.
# =============================================================================
{ inputs, pkgs, lib, ... }:
let
  # Programs noctalia runs. Each one corresponds to a feature in the bar.
  runtimeDeps = with pkgs; [
    accountsservice     # user account name and avatar
    brightnessctl       # screen brightness
    cava                # audio visualiser
    cliphist            # clipboard history panel
    ddcutil             # brightness on external monitors
    glib                # gsettings, used for the colour scheme sync
    gpu-screen-recorder # the screen recorder in the control centre
    gsettings-desktop-schemas
    material-symbols    # the icon font the bar draws with
    awww                # wallpaper daemon (formerly named swww)
    wl-clipboard
    wget
    python3             # helper scripts
    imagemagick         # wallpaper colour extraction
  ];

  # Qt modules noctalia imports.
  qtDeps = with pkgs.kdePackages; [
    qtbase
    qtdeclarative
    qtmultimedia
    qtwayland
    kirigami
  ];

  allDeps = runtimeDeps ++ qtDeps;

  noctalia = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.myNoctalia;

  noctaliaWrapped = pkgs.runCommand "noctalia-wrapped" {
    nativeBuildInputs = [ pkgs.makeWrapper ];
  } ''
    mkdir -p $out/bin

    for bin in ${noctalia}/bin/*; do
      makeWrapper "$bin" "$out/bin/$(basename "$bin")" \
        --prefix PATH : "${lib.makeBinPath allDeps}" \
        --prefix QML2_IMPORT_PATH : "${lib.makeSearchPath "lib/qt-6/qml" allDeps}"
    done
  '';
in
{
  home.packages = [ noctaliaWrapped ];
}
