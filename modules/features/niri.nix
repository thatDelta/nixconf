{ self, inputs, ... }: {
  flake.nixosModules.niri = { pkgs, lib, ... }: {
    programs.niri.enable = true;
    # Do NOT set package here - use standard niri so it reads ~/.config/niri/config.kdl
    # myNoctalia is in home.packages (via yume.nix) so noctalia-shell is in PATH
  };

  perSystem = { pkgs, lib, self', ... }: {
    packages.myNiri = inputs.wrapper-modules.wrappers.niri.wrap {
      inherit pkgs; # THIS PART IS VERY IMPORTAINT, I FORGOT IT IN THE VIDEO!!!
      settings = {
        spawn-at-startup = [
          (lib.getExe self'.packages.myNoctalia)
        ];

        xwayland-satellite.path = lib.getExe pkgs.xwayland-satellite;

        input.keyboard.xkb.layout = "us,ua";

        layout.gaps = 5;

        binds = {
  "Mod+Return".spawn-sh = lib.getExe pkgs.kitty;
  "Mod+Q".close-window = {}; 
  "Mod+S".spawn-sh = "${lib.getExe self'.packages.myNoctalia} ipc call launcher toggle";
        };
      };
    };
  };
}
