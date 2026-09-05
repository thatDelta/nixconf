# =============================================================================
# niri configuration  --  assembled here, written to ~/.config/niri/config.kdl
# =============================================================================
#
# niri is configured in KDL, a config language Nix knows nothing about. So the
# config is written as ordinary Nix attribute sets in the files beside this
# one, and _to-KDL.nix translates the result into KDL text.
#
# THE FILES (underscore = "a piece of data, not a module you import directly")
#   _settings.nix   inputs, outputs, layout, startup programs, appearance
#   _binds.nix      every keyboard shortcut
#   _rules.nix      per-application window rules (what opens floating, etc.)
#   _to-KDL.nix     the Nix -> KDL translator; you will not need to touch this
#
# WHERE THE FILE ENDS UP
#   ~/.config/niri/config.kdl, as a read-only symlink into /nix/store.
#   To change a keybind you edit _binds.nix and rebuild -- editing the symlink
#   target directly is not possible, and that is the point: the file in git is
#   always what is actually running.
#
# CHECKING YOUR WORK
#   niri validates its config on load. After a rebuild:
#       niri validate -c ~/.config/niri/config.kdl
#   catches a typo before you log out and find a broken session.
# =============================================================================
{ pkgs, lib, ... }:
let
  toKDL = import ./_to-KDL.nix { inherit lib pkgs; };

  settings = import ./_settings.nix { inherit lib pkgs; };
  binds = import ./_binds.nix { inherit lib pkgs; };
  rules = import ./_rules.nix;

  # The three parts are merged into the single attribute set that becomes the
  # config file. `binds` has to be nested under a `binds` key because that is
  # how it appears in KDL; settings and rules are already top-level.
  niriConfig = settings // { binds = binds; } // rules;
in
{
  xdg.configFile."niri/config.kdl".source =
    toKDL.generate "niri-config.kdl" niriConfig;
}
