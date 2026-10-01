# =============================================================================
# yume  --  the applications for this profile
# =============================================================================
#
# THE RULE FOR THIS FILE
#   Things you use as a person, on THIS desktop. If a different profile would
#   also want it on any machine, it belongs in modules/core/packages.nix
#   instead.
#
# WHY THESE ARE USER PACKAGES, NOT SYSTEM PACKAGES
#   Installing here means they land in your home profile: you can add one and
#   rebuild without touching the system closure, and a second user on this
#   machine does not silently inherit your application list.
# =============================================================================
{ self, inputs, pkgs, ... }:
let
  # Packages that come from flake inputs rather than nixpkgs. Pulled out here
  # so the main list below stays readable.
  llm = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  home.packages = (with pkgs; [

    # --- browsers ---------------------------------------------------------
    # firefox is the default (Mod+B, and the handler for http/https below).
    #
    # Installed as a plain package rather than through `programs.firefox`,
    # deliberately: that module can manage profiles, and this profile is 1.6GB
    # of real history/logins living in ~/.config/mozilla. A plain package
    # install cannot write there at all.
    #
    # (Firefox 153+ follows the XDG base directory spec, which is why the
    # profile is in ~/.config/mozilla and not the older ~/.mozilla.)
    firefox
    google-chrome

    # --- terminals --------------------------------------------------------
    kitty          # the default, bound to Mod+T
    foot           # lightweight fallback; useful if kitty ever fails to start

    # --- files ------------------------------------------------------------
    kdePackages.dolphin   # graphical, bound to Mod+E
    yazi                  # terminal file manager
    file-roller           # archive extraction from the file manager

    # --- media ------------------------------------------------------------
    mpv
    swayimg               # image viewer
    pwvucontrol           # audio mixer (PipeWire native)

    # --- gaming -------------------------------------------------------------
    # Epic Games Store / GOG / Amazon storefront client, plus a Wine/Proton
    # frontend for running Windows-only games -- the Linux equivalent of the
    # Epic/GOG launchers.
    heroic

    # --- wayland utilities ------------------------------------------------
    # These are what make copy/paste, screenshots and X11 apps work. They look
    # optional and are not.
    wl-clipboard          # clipboard access for command-line tools
    cliphist              # clipboard HISTORY, behind Mod+V
    xwayland-satellite    # runs X11-only apps under niri
    libnotify             # lets scripts send desktop notifications
    xdg-utils             # xdg-open, "open this file with the right app"

    # --- appearance -------------------------------------------------------
    matugen               # generates a colour scheme from your wallpaper
    adw-gtk3
    gsettings-desktop-schemas

    # --- shell tools ------------------------------------------------------
    atuin                 # searchable shell history
    grc                   # colourises command output
    imagemagick
  ])

  # --- AI tooling (from the llm-agents flake input) -----------------------
  ++ [
    llm.claude-code       # the CLI
    llm.claude-desktop
  ]

  # --- iOS sideloading -----------------------------------------------------
  # Installs SideStore etc onto a connected iPhone/iPad. Packaged in
  # modules/features/ios-tools.nix (see that file for why it's not just a
  # flake input), which also enables the usbmuxd daemon it needs to actually
  # see the device.
  ++ [
    self.packages.${pkgs.stdenv.hostPlatform.system}.iloader
  ];
}
