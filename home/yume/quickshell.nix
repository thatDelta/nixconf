{
  inputs,
  pkgs,
  lib,
  self,
  ...
}: let
  quickshellDeps = with pkgs;
    [
      accountsservice
      brightnessctl
      cava
      cliphist
      ddcutil
      elogind
      glib
      gpu-screen-recorder
      gsettings-desktop-schemas
      material-symbols
      swww
      wl-clipboard
      wget
      python3
      imagemagick
    ]
    ++ (with pkgs.kdePackages; [
      qtbase
      qtdeclarative
      qt6ct
      qtmultimedia
      qtwayland
      kirigami
    ]);

  userPackages = with pkgs; [
    matugen
    gsettings-desktop-schemas
  ];

  quickshellWrapped =
    pkgs.runCommand "quickshell-wrapped" {
      buildInputs = [pkgs.makeWrapper];
    } ''
      mkdir -p $out/bin
      paths="${pkgs.lib.makeBinPath quickshellDeps}"
      qmlPaths="${lib.makeSearchPath "lib/qt-6/qml" quickshellDeps}:${lib.makeSearchPath "lib/qt-5/qml" quickshellDeps}"


      for bin in ${self.packages.${pkgs.system}.myNoctalia}/bin/*; do
        name=$(basename "$bin")
        makeWrapper "$bin" "$out/bin/$name" \
          --prefix QML2_IMPORT_PATH : "$qmlPaths" \
          --prefix PATH : "$paths"
      done
    '';
in [ quickshellWrapped ] ++ userPackages
