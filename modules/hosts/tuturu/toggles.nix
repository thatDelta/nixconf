# =============================================================================
# toggles  --  one command (and control-centre buttons) for the iPad setup
# =============================================================================
#
#   tuturu-ctl status                     what's on right now
#   tuturu-ctl notify                     same, as a notification
#   tuturu-ctl on|off|toggle  THING       THING is one of:
#       sunshine   streaming to Moonlight          (user service)
#       jellyfin   the anime library               (jellyfin.nix)
#       hotspot    laptop Wi-Fi hotspot for iPad   (ipad-hotspot.nix)
#       hdmi       fake iPad monitor vs a real one (ipad-display.nix)
#       ipad       all of the above for streaming to the iPad at once
#   tuturu-ctl is-on THING                exit 0 if on (used by the buttons)
#
# THE BUTTONS live in noctalia's control centre (modules/features/
# noctalia.json, controlCenter.shortcuts): left click toggles, right click
# opens the thing's page (Sunshine web UI, Jellyfin). A lit button is on.
#
# NO PASSWORD PROMPTS: the polkit rule below lets your user start/stop
# exactly these three system services, nothing else.
# =============================================================================
{ ... }:
{
  flake.nixosModules.tuturuToggles =
    { pkgs, config, ... }:
    let
      ctl = pkgs.writeShellApplication {
        name = "tuturu-ctl";
        runtimeInputs = [ pkgs.systemd pkgs.libnotify ];
        text = ''
          unit_of() {
            case "$1" in
              jellyfin) echo jellyfin.service ;;
              hotspot)  echo ipad-hotspot.service ;;
              hdmi)     echo hdmi-virtual.service ;;
              *)        return 1 ;;
            esac
          }

          sc() {  # systemctl, --user for sunshine
            if [ "$2" = sunshine ]; then
              systemctl --user "$1" sunshine.service
            else
              systemctl "$1" "$(unit_of "$2")"
            fi
          }

          # "activating" counts as on, so a button lights up straight away.
          is_on() {
            local state
            if [ "$1" = ipad ]; then
              is_on hotspot && is_on sunshine && is_on hdmi
              return
            fi
            state=$(sc is-active "$1" || true)
            [ "$state" = active ] || [ "$state" = activating ] || [ "$state" = reloading ]
          }

          set_state() {  # set_state on|off THING
            local verb=start
            [ "$1" = off ] && verb=stop
            if [ "$2" = ipad ]; then
              for t in hdmi hotspot sunshine; do set_state "$1" "$t"; done
              return
            fi
            if ! err=$(sc "$verb" "$2" 2>&1); then
              notify-send -a tuturu-ctl "Couldn't turn $2 $1" "$err"
              # the hotspot's own reason (e.g. a DFS channel) is in its log
              [ "$2" = hotspot ] && notify-send -a tuturu-ctl "hotspot" \
                "$(journalctl -u ipad-hotspot -n 3 -o cat 2>/dev/null)"
              return 1
            fi
          }

          status() {
            for t in sunshine jellyfin hotspot hdmi; do
              if is_on "$t"; then s=on; else s=off; fi
              [ "$t" = hdmi ] && { [ $s = on ] && s="virtual (iPad)" || s="physical"; }
              printf '%-9s %s\n' "$t" "$s"
            done
          }

          case "''${1:-status}" in
            status) status ;;
            notify) notify-send -a tuturu-ctl "tuturu" "$(status)" ;;
            is-on)  is_on "$2" ;;
            on|off) set_state "$1" "$2" ;;
            toggle) if is_on "$2"; then set_state off "$2"; else set_state on "$2"; fi ;;
            *) echo "usage: tuturu-ctl status | on|off|toggle|is-on sunshine|jellyfin|hotspot|hdmi|ipad" >&2; exit 2 ;;
          esac
        '';
      };
    in
    {
      environment.systemPackages = [ ctl ];

      security.polkit.extraConfig = ''
        polkit.addRule(function (action, subject) {
          var units = ["jellyfin.service", "ipad-hotspot.service", "hdmi-virtual.service"];
          if (action.id == "org.freedesktop.systemd1.manage-units" &&
              subject.user == "${config.my.username}" &&
              units.indexOf(action.lookup("unit")) >= 0) {
            return polkit.Result.YES;
          }
        });
      '';
    };
}
