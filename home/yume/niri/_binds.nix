# =============================================================================
# niri keybinds  --  ported from end4/dots-hyprland to niri
# =============================================================================
#
# HOW TO READ A LINE IN THIS FILE
#
#   "Mod+Q".close-window = {};
#    ^key    ^niri action  ^no arguments
#
#   "Mod+1".focus-workspace = 1;          action WITH an argument
#   "Mod+T".spawn._args = [ "kitty" ];    run a program (_args = the argv list)
#
#   "Mod" is the Super / Windows key.
#   `_props` sets KDL properties on the bind, e.g. allow-when-locked=true
#   means the key still works while the lock screen is up (volume keys should,
#   "close window" should not).
#
# WHY SOME COMMANDS ARE FULL /nix/store PATHS AND OTHERS ARE BARE NAMES
#   Applications use `lib.getExe pkgs.foo`, which bakes in an absolute path --
#   the bind then works even if PATH is wrong or the package was removed from
#   your profile (you get a clear error instead of silence).
#   `noctalia-shell` is deliberately left bare: the copy on PATH is a wrapped
#   build with the right Qt/QML environment, and hardcoding the unwrapped store
#   path would launch a broken shell.
#
# WHERE THE ACTION NAMES COME FROM
#   niri actions:   `niri msg action --help`
#   noctalia IPC:   `noctalia-shell ipc show`
#   Both are worth running when you want a key this file does not bind.
# =============================================================================
{ pkgs, lib, ... }:
let
  # --- your applications ------------------------------------------------
  # Change these four lines to re-point every app keybind below.
  terminal = lib.getExe pkgs.kitty;
  browser = lib.getExe pkgs.firefox;
  #fileManager = lib.getExe pkgs.kdePackages.dolphin;
  fileManager = lib.getExe pkgs.yazi;
  # Mod+C "code editor". Swap the line below for whichever you prefer:
  #
  #   LazyVim (current)   "${terminal} -e ${lib.getExe pkgs.neovim}"
  #   Antigravity IDE     lib.getExe inputs.antigravity-nix.packages.${pkgs.system}.google-antigravity-ide
  #   Claude Desktop      lib.getExe inputs.llm-agents.packages.${pkgs.system}.claude-desktop
  #   Claude Code (CLI)   "${terminal} -e claude"
  #   yazi file browser   "${terminal} -e ${lib.getExe pkgs.yazi}"
  #
  # (The IDE options need `inputs` in this file's arguments -- add it to the
  # function header at the top and to the import in ./default.nix.)
  codeEditor = terminal;
  codeEditorArgs = [ "-e" (lib.getExe pkgs.neovim) ];

  # Shorthand for the many noctalia IPC calls below.
  noctalia = args: { spawn._args = [ "noctalia-shell" "ipc" "call" ] ++ args; };

  # Same, but keeps working while the screen is locked (media/volume keys).
  noctaliaLocked = args: (noctalia args) // { _props.allow-when-locked = true; };
in
{
  # ===========================================================================
  # APPLICATIONS
  # ===========================================================================
  "Mod+T".spawn._args = [ terminal ];              # terminal
  "Mod+Return".spawn._args = [ terminal ];         # terminal (niri default)
  "Mod+E".spawn._args = [ fileManager ];           # files
  "Mod+B".spawn._args = [ browser ];               # browser
  "Mod+C".spawn._args = [ codeEditor ] ++ codeEditorArgs;

  # ===========================================================================
  # DESKTOP SHELL  (noctalia panels)
  # ===========================================================================
  "Mod+D" = noctalia [ "launcher" "toggle" ];        # app launcher
  "Mod+V" = noctalia [ "launcher" "clipboard" ];     # clipboard history
  "Mod+Period" = noctalia [ "launcher" "emoji" ];    # emoji picker
  "Mod+N" = noctalia [ "controlCenter" "toggle" ];   # control centre
  "Mod+Shift+N" = noctalia [ "notifications" "toggleHistory" ];
  "Mod+U" = noctalia [ "settings" "toggle" ];        # noctalia settings panel
  "Mod+M" = noctalia [ "media" "toggle" ];           # media controls
  "Mod+Slash" = noctalia [ "calendar" "toggle" ];    # calendar

  # Caffeine. This is the toggle that was keeping the machine awake --
  # it is now on a key you can check rather than a menu you forget about.
  "Mod+I" = noctalia [ "idleInhibitor" "toggle" ];

  # Appearance
  "Ctrl+Mod+T" = noctalia [ "wallpaper" "toggle" ];        # wallpaper picker
  "Ctrl+Mod+Alt+T" = noctalia [ "wallpaper" "random" ];    # random wallpaper
  "Ctrl+Mod+Shift+D" = noctalia [ "darkMode" "toggle" ];   # light/dark

  # ===========================================================================
  # SESSION
  # ===========================================================================
  # end4 puts lock on Super+L, but niri needs Super+L for "focus the column to
  # the right" (the vim h/j/k/l navigation below), and that key gets used
  # hundreds of times a day. So the session keys live on Ctrl+Alt instead --
  # the same place most desktops put them.
  "Ctrl+Alt+L" = noctalia [ "lockScreen" "lock" ];
  "Ctrl+Alt+S" = noctalia [ "sessionMenu" "lockAndSuspend" ];    # lock + sleep
  "Ctrl+Alt+Delete" = noctalia [ "sessionMenu" "toggle" ];       # power menu

  # ===========================================================================
  # WINDOWS
  # ===========================================================================
  "Mod+Q".close-window = { };
  "Mod+F".fullscreen-window = { };                 # true fullscreen
  "Mod+Shift+F".maximize-column = { };             # fill the screen, keep bar
  "Mod+Ctrl+F".expand-column-to-available-width = { };

  "Mod+Space".toggle-window-floating = { };        # float / tile this window
  "Mod+Shift+Space".switch-focus-between-floating-and-tiling = { };

  "Mod+W".toggle-column-tabbed-display = { };      # stack column as tabs
  "Mod+Tab".toggle-overview = { };                 # zoomed-out overview

  # Columns hold one or more windows side by side. "Consume" pulls the next
  # window into this column; "expel" pushes it back out into its own.
  "Mod+Comma".consume-or-expel-window-left = { };
  "Mod+Shift+Comma".consume-or-expel-window-right = { };

  # ===========================================================================
  # FOCUS  --  vim keys and arrow keys do the same thing
  # ===========================================================================
  "Mod+H".focus-column-left = { };
  "Mod+L".focus-column-right = { };
  "Mod+J".focus-window-or-workspace-down = { };
  "Mod+K".focus-window-or-workspace-up = { };

  "Mod+Left".focus-column-left = { };
  "Mod+Right".focus-column-right = { };
  "Mod+Down".focus-window-or-workspace-down = { };
  "Mod+Up".focus-window-or-workspace-up = { };

  "Mod+Home".focus-column-first = { };
  "Mod+End".focus-column-last = { };

  # Move the focused window instead of the focus.
  "Mod+Shift+H".move-column-left = { };
  "Mod+Shift+L".move-column-right = { };
  "Mod+Shift+J".move-window-down = { };
  "Mod+Shift+K".move-window-up = { };

  "Mod+Shift+Left".move-column-left = { };
  "Mod+Shift+Right".move-column-right = { };
  "Mod+Shift+Down".move-window-down = { };
  "Mod+Shift+Up".move-window-up = { };

  # Across physical monitors.
  "Mod+Ctrl+Left".focus-monitor-left = { };
  "Mod+Ctrl+Right".focus-monitor-right = { };
  "Mod+Ctrl+Shift+Left".move-column-to-monitor-left = { };
  "Mod+Ctrl+Shift+Right".move-column-to-monitor-right = { };

  # ===========================================================================
  # WORKSPACES
  # ===========================================================================
  # In niri workspaces stack VERTICALLY on each monitor, so "up/down" rather
  # than "left/right".
  "Mod+Page_Down".focus-workspace-down = { };
  "Mod+Page_Up".focus-workspace-up = { };
  "Mod+Shift+Page_Down".move-column-to-workspace-down = { };
  "Mod+Shift+Page_Up".move-column-to-workspace-up = { };

  # Mod+scroll wheel moves between workspaces.
  "Mod+WheelScrollDown" = {
    _props.cooldown-ms = 150;
    focus-workspace-down = { };
  };
  "Mod+WheelScrollUp" = {
    _props.cooldown-ms = 150;
    focus-workspace-up = { };
  };

  # Jump straight to a numbered workspace, and Shift to take the window along.
  "Mod+1".focus-workspace = 1;
  "Mod+2".focus-workspace = 2;
  "Mod+3".focus-workspace = 3;
  "Mod+4".focus-workspace = 4;
  "Mod+5".focus-workspace = 5;
  "Mod+6".focus-workspace = 6;
  "Mod+7".focus-workspace = 7;
  "Mod+8".focus-workspace = 8;
  "Mod+9".focus-workspace = 9;

  "Mod+Shift+1".move-column-to-workspace = 1;
  "Mod+Shift+2".move-column-to-workspace = 2;
  "Mod+Shift+3".move-column-to-workspace = 3;
  "Mod+Shift+4".move-column-to-workspace = 4;
  "Mod+Shift+5".move-column-to-workspace = 5;
  "Mod+Shift+6".move-column-to-workspace = 6;
  "Mod+Shift+7".move-column-to-workspace = 7;
  "Mod+Shift+8".move-column-to-workspace = 8;
  "Mod+Shift+9".move-column-to-workspace = 9;

  # ===========================================================================
  # SIZING
  # ===========================================================================
  "Mod+R".switch-preset-column-width = { };        # cycle 25/50/75/100%
  "Mod+Shift+R".reset-window-height = { };
  "Mod+Ctrl+C".center-column = { };

  "Mod+Minus".set-column-width = "-10%";
  "Mod+Equal".set-column-width = "+10%";
  "Mod+Shift+Minus".set-window-height = "-10%";
  "Mod+Shift+Equal".set-window-height = "+10%";

  # ===========================================================================
  # SCREENSHOTS
  # ===========================================================================
  "Print".screenshot-screen = { };                 # whole screen
  "Mod+Shift+S".screenshot = { };                  # select a region
  "Mod+Shift+Alt+S".screenshot-window = { };       # just this window

  # Pick a colour off the screen, copy it as #RRGGBB.
  "Mod+Shift+C".spawn._args = [
    "fish"
    "-c"
    "niri msg pick-color | grep -oP '#[0-9a-fA-F]+' | wl-copy"
  ];

  # ===========================================================================
  # HARDWARE KEYS
  # ===========================================================================
  # These keep working on the lock screen, which is why they use the
  # `noctaliaLocked` helper -- you should be able to mute a laptop without
  # unlocking it first.
  "XF86AudioRaiseVolume" = noctaliaLocked [ "volume" "increase" ];
  "XF86AudioLowerVolume" = noctaliaLocked [ "volume" "decrease" ];
  "XF86AudioMute" = noctaliaLocked [ "volume" "muteOutput" ];
  "XF86AudioMicMute" = noctaliaLocked [ "volume" "muteInput" ];

  "XF86MonBrightnessUp" = noctaliaLocked [ "brightness" "increase" ];
  "XF86MonBrightnessDown" = noctaliaLocked [ "brightness" "decrease" ];

  "XF86AudioPlay" = noctaliaLocked [ "media" "playPause" ];
  "XF86AudioPause" = noctaliaLocked [ "media" "playPause" ];
  "XF86AudioStop" = noctaliaLocked [ "media" "stop" ];
  "XF86AudioNext" = noctaliaLocked [ "media" "next" ];
  "XF86AudioPrev" = noctaliaLocked [ "media" "previous" ];

  # Same three on the keyboard, for keyboards without media keys.
  "Mod+Shift+P" = noctaliaLocked [ "media" "playPause" ];
  "Mod+Shift+Period" = noctaliaLocked [ "media" "next" ];
  "Mod+Shift+M" = noctaliaLocked [ "volume" "muteOutput" ];

  # ===========================================================================
  # NIRI ITSELF
  # ===========================================================================
  "Mod+Shift+Slash".show-hotkey-overlay = { };     # "what are my keybinds?"
  "Mod+Shift+E".quit = { };                        # log out of niri
  "Ctrl+Alt+F1".toggle-keyboard-shortcuts-inhibit = { };  # release keys to a VM
}
