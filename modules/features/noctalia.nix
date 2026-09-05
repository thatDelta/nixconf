# =============================================================================
# noctalia  --  the desktop shell (bar, launcher, notifications, lock screen)
# =============================================================================
#
# noctalia is a Quickshell-based desktop shell. It draws the top bar, the app
# launcher, the notification popups, the control centre and the lock screen.
# niri only manages windows; everything else you see on screen is noctalia.
#
# HOW ITS SETTINGS WORK
#   noctalia normally keeps mutable settings in ~/.config/noctalia/settings.json
#   and rewrites that file whenever you change something in its settings panel.
#
#   Here the settings are declared instead: noctalia.json in this directory is
#   baked into a wrapped build of the program. That makes the look of the bar
#   reproducible and version-controlled, at the cost of the settings panel's
#   changes not surviving a rebuild.
#
#   TO CHANGE THE BAR:  edit noctalia.json, then rebuild.
#   TO EXPERIMENT:      change it live in the settings panel, then copy the
#                       values you liked out of ~/.config/noctalia/settings.json
#                       into noctalia.json so they stick.
#
# The package is exposed as a flake output (`myNoctalia`) rather than
# installed here, because the profile wraps it once more to inject runtime
# dependencies -- see home/yume/quickshell.nix.
# =============================================================================
{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.myNoctalia = inputs.wrapper-modules.wrappers.noctalia-shell.wrap {
        inherit pkgs;

        settings = (builtins.fromJSON (builtins.readFile ./noctalia.json)).settings;
      };
    };
}
