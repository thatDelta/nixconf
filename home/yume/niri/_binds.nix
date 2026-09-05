{pkgs, ...}: {
  "XF86AudioPlay" = {
    _props.allow-when-locked = true;
    spawn._args = ["noctalia-shell" "ipc" "call" "media" "playPause"];
  };
  "XF86AudioStop" = {
    _props.allow-when-locked = true;
    spawn._args = ["noctalia-shell" "ipc" "call" "media" "stop"];
  };
  "XF86AudioNext" = {
    _props.allow-when-locked = true;
    spawn._args = ["noctalia-shell" "ipc" "call" "media" "next"];
  };
  "XF86AudioPrev" = {
    _props.allow-when-locked = true;
    spawn._args = ["noctalia-shell" "ipc" "call" "media" "previous"];
  };
  "XF86AudioMute" = {
    _props.allow-when-locked = true;
    spawn._args = ["noctalia-shell" "ipc" "call" "volume" "muteOutput"];
  };
  "XF86AudioMicMute" = {
    _props.allow-when-locked = true;
    spawn._args = ["noctalia-shell" "ipc" "call" "volume" "muteInput"];
  };
  "XF86AudioRaiseVolume" = {
    _props.allow-when-locked = true;
    spawn._args = ["noctalia-shell" "ipc" "call" "volume" "increase"];
  };
  "XF86AudioLowerVolume" = {
    _props.allow-when-locked = true;
    spawn._args = ["noctalia-shell" "ipc" "call" "volume" "decrease"];
  };
  "XF86MonBrightnessUp" = {
    _props.allow-when-locked = true;
    spawn._args = ["noctalia-shell" "ipc" "call" "brightness" "increase"];
  };
  "XF86MonBrightnessDown" = {
    _props.allow-when-locked = true;
    spawn._args = ["noctalia-shell" "ipc" "call" "brightness" "decrease"];
  };
  "Ctrl+Alt+L".spawn._args = ["noctalia-shell" "ipc" "call" "lockScreen" "lock"];
  "Mod+V".spawn._args = ["noctalia-shell" "ipc" "call" "launcher" "clipboard"];
  "Mod+E".spawn._args = ["noctalia-shell" "ipc" "call" "launcher" "emoji"];
  "Mod+U".spawn._args = ["noctalia-shell" "ipc" "call" "settings" "toggle"];
  "Mod+D".spawn._args = ["noctalia-shell" "ipc" "call" "launcher" "toggle"];
  "Print".screenshot-screen = {};
  "Mod+Shift+Alt+S".screenshot-window = {};
  "Mod+Shift+S".screenshot = {};
  "Mod+Return".spawn._args = ["${pkgs.kitty}/bin/kitty"];
  "Mod+Q".close-window = {};
  "Mod+X".spawn._args = ["fish" "-c" "niri msg pick-color | grep -oP '#[0-9a-fA-F]+' | wl-copy"];
  "Mod+S".switch-preset-column-width = {};
  "Mod+F".maximize-column = {};
  "Mod+Alt+F".spawn._args = ["fish" "-c" "niri msg action toggle-windowed-fullscreen --id $(niri msg --json pick-window | jq '.id')"];
  "Mod+1".set-column-width = "25%";
  "Mod+2".set-column-width = "50%";
  "Mod+3".set-column-width = "75%";
  "Mod+4".set-column-width = "100%";
  "Mod+Shift+F".expand-column-to-available-width = {};
  "Mod+Space".toggle-window-floating = {};
  "Mod+W".toggle-column-tabbed-display = {};
  "Mod+Comma".consume-window-into-column = {};
  "Mod+Period".expel-window-from-column = {};
  "Mod+C".center-visible-columns = {};
  "Mod+Tab".switch-focus-between-floating-and-tiling = {};
  "Mod+Minus".set-column-width = "-10%";
  "Mod+Plus".set-column-width = "+10%";
  "Mod+Shift+Minus".set-window-height = "-10%";
  "Mod+Shift+Plus".set-window-height = "+10%";
  "Mod+H".focus-column-left = {};
  "Mod+L".focus-column-right = {};
  "Mod+J".focus-window-or-workspace-down = {};
  "Mod+K".focus-window-or-workspace-up = {};
  "Mod+Left".focus-column-left = {};
  "Mod+Right".focus-column-right = {};
  "Mod+Down".focus-workspace-down = {};
  "Mod+Up".focus-workspace-up = {};
  "Mod+Shift+H".move-column-left = {};
  "Mod+Shift+L".move-column-right = {};
  "Mod+Shift+K".move-column-to-workspace-up = {};
  "Mod+Shift+J".move-column-to-workspace-down = {};
  "Mod+Shift+Ctrl+J".move-column-to-monitor-down = {};
  "Mod+Shift+Ctrl+K".move-column-to-monitor-up = {};
  "Mod+Ctrl+K".focus-window-or-monitor-up = {};
  "Mod+Ctrl+J".focus-window-or-monitor-down = {};
}
