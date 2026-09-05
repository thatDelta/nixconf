{
  inputs,
  lib,
  pkgs,
  ...
}: let
  toKDL = import ./_to-KDL.nix {inherit lib pkgs;};
  settings = import ./_settings.nix {inherit lib pkgs;};
  binds = import ./_binds.nix {inherit inputs pkgs;};
  rules = import ./_rules.nix;

  finalConfig = toKDL.generate "niri-config.kdl" (settings // {binds = binds;} // rules);
in {
  environment.sessionVariables = {
    NIRI_CONFIG = "$HOME/.config/niri/config.kdl";
  };

  users.users.linuxmobile.packages = with pkgs; [niri];

  xdg.configFile."niri/config.kdl".text = builtins.readFile finalConfig;
}
