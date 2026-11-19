# psiphon -- control the Psiphon VPN (modules/features/psiphon.nix)
#
#   psiphon                 interactive menu (TUI)
#   psiphon status          one-line-per-item status
#   psiphon on|off|toggle
#   psiphon region [CC|best]   exit country (no arg: pick from a list)
#   psiphon mode vpn|proxy     whole system, or only apps pointed at the proxy
#   psiphon ip              public IP + country, as seen through Psiphon
#   psiphon log             follow the connection log
#
# Settings live in $SETTINGS (owned by you, so no sudo); the service reads them
# each time it starts. Changing one while connected reconnects.

usage() {
  cat <<'USAGE'
psiphon                    interactive menu
psiphon status             what is on right now
psiphon on|off|toggle
psiphon region [CC|best]   exit country (no CC: list them)
psiphon mode vpn|proxy     whole system, or only apps using the proxy
psiphon ip                 public IP and country through Psiphon
psiphon log                follow the connection log
USAGE
}

SETTINGS=/var/lib/psiphon-settings/settings.json
NOTICES=/run/psiphon/notices.jsonl
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/psiphon"
SOCKS=127.0.0.1:1081

# Psiphon's usual exit countries, used until a connection reports the real list.
FALLBACK_REGIONS="AT BE BG CA CH CZ DE DK EE ES FI FR GB HU IE IN IT JP LV NL NO PL RO RS SE SG SK US"

# --- settings ---------------------------------------------------------------
ensure_settings() {
  [ -s "$SETTINGS" ] || echo '{"region":"","mode":"vpn"}' >"$SETTINGS"
}

get() { jq -r --arg k "$1" '.[$k] // ""' "$SETTINGS" 2>/dev/null || true; }

put() {
  ensure_settings
  local tmp
  tmp=$(mktemp)
  jq --arg k "$1" --arg v "$2" '.[$k] = $v' "$SETTINGS" >"$tmp" && cat "$tmp" >"$SETTINGS"
  rm -f "$tmp"
}

mode() { local m; m=$(get mode); echo "${m:-vpn}"; }

# --- state ------------------------------------------------------------------
is_on() { systemctl is-active --quiet psiphon.service; }

# last value of a notice field from this session's log
notice() {  # notice <noticeType> <jq path under .data>
  [ -r "$NOTICES" ] || return 0
  jq -R -r --arg t "$1" "fromjson? | select(.noticeType == \$t) | .data$2 | tostring" "$NOTICES" 2>/dev/null | tail -n1
}

is_connected() { local n; n=$(notice Tunnels .count); [ -n "$n" ] && [ "$n" != 0 ]; }

wait_connected() { for _ in $(seq 30); do is_connected && return 0; sleep 0.5; done; return 1; }

regions() {
  local live
  live=$(notice AvailableEgressRegions '.regions | join(" ")')
  if [ -n "$live" ]; then
    mkdir -p "$CACHE" && echo "$live" >"$CACHE/regions"
    echo "$live"
  elif [ -s "$CACHE/regions" ]; then
    cat "$CACHE/regions"
  else
    echo "$FALLBACK_REGIONS"
  fi
}

status_lines() {
  local r m
  r=$(get region); m=$(mode)
  if ! is_on; then
    echo "Psiphon   ○ off"
  elif is_connected; then
    echo "Psiphon   ● connected  (server in $(notice ConnectedServerRegion .serverRegion))"
  else
    echo "Psiphon   ◌ connecting..."
  fi
  if [ "$m" = vpn ]; then
    echo "Mode      VPN -- whole system"
    if is_on && ! systemctl is-active --quiet psiphon-tun.service; then
      echo "          (! tunnel device not up -- check: psiphon log)"
    fi
  else
    echo "Mode      proxy only -- SOCKS $SOCKS, HTTP 127.0.0.1:8081"
  fi
  echo "Region    ${r:-best available}"
}

# --- actions ----------------------------------------------------------------
say() {  # print in a terminal, notify otherwise (e.g. run from the launcher)
  if [ -t 1 ]; then echo "$*"; else notify-send -a Psiphon -i network-vpn "Psiphon" "$*"; fi
}

turn_on() {
  ensure_settings
  if systemctl start psiphon.service; then
    say "Psiphon on -- connecting ($( [ "$(mode)" = vpn ] && echo whole system || echo proxy only ))"
  else
    say "Psiphon failed to start: $(systemctl status psiphon.service --no-pager -n 3 2>&1 | tail -n 3)"
    return 1
  fi
}

turn_off() { systemctl stop psiphon.service && say "Psiphon off"; }

reconnect_if_on() {
  if is_on; then
    systemctl restart psiphon.service
    [ "$(mode)" = vpn ] && systemctl start psiphon-tun.service
    say "Reconnecting with the new setting..."
  fi
}

set_region() {
  local r="${1:-}"
  case "$r" in best|any|"") r="" ;; *) r=$(echo "$r" | tr '[:lower:]' '[:upper:]') ;; esac
  put region "$r"
  say "Region: ${r:-best available}"
  reconnect_if_on
}

set_mode() {
  case "${1:-}" in
    vpn)   put mode vpn;   is_on && systemctl start psiphon-tun.service; say "Mode: VPN (whole system)" ;;
    proxy) put mode proxy; is_on && systemctl stop psiphon-tun.service;  say "Mode: proxy only (SOCKS $SOCKS)" ;;
    *) echo "usage: psiphon mode vpn|proxy" >&2; return 2 ;;
  esac
}

show_ip() {
  if ! is_on; then echo "Psiphon is off."; return 1; fi
  # Always ask via the SOCKS port, so the answer is Psiphon's exit in either mode.
  curl -s -m 8 --socks5-hostname "$SOCKS" https://ipinfo.io/json \
    | jq -r '"IP        \(.ip)\nExit      \(.city // "?"), \(.country // "?")  (\(.org // "?"))"' 2>/dev/null \
    || echo "No answer yet -- still connecting?"
}

follow_log() {
  if [ ! -r "$NOTICES" ]; then echo "No log -- Psiphon is off."; return 1; fi
  echo "(Ctrl+C to stop)"
  tail -n 30 -f "$NOTICES" | jq -R -r --unbuffered \
    'fromjson? | "\(.timestamp[11:19])  \(.noticeType)  \(.data | tostring | .[0:140])"'
}

# --- TUI --------------------------------------------------------------------
tui() {
  ensure_settings
  while true; do
    clear
    gum style --border rounded --padding "0 2" --border-foreground 212 \
      "$(gum style --bold --foreground 212 'Psiphon')" "" "$(status_lines)"

    local power choice
    if is_on; then power="Turn off"; else power="Turn on"; fi
    choice=$(gum choose --header "" \
      "$power" \
      "Region: $(r=$(get region); echo "${r:-best available}")" \
      "Mode: $( [ "$(mode)" = vpn ] && echo 'VPN (whole system)' || echo 'proxy only' )" \
      "Check my IP" \
      "Log" \
      "Refresh" \
      "Quit") || return 0

    case "$choice" in
      "Turn on")  gum spin --title "Starting..." -- systemctl start psiphon.service \
                    || { echo "Failed to start."; sleep 2; }
                  # wait (up to ~15s) for a tunnel so the status means something
                  gum spin --title "Connecting..." -- bash -c \
                    "$(declare -f notice is_connected wait_connected); NOTICES=$NOTICES wait_connected" || true ;;
      "Turn off") gum spin --title "Stopping..." -- systemctl stop psiphon.service ;;
      Region*)
        local pick
        pick=$( { echo "best available"; regions | tr ' ' '\n'; } \
                | gum filter --placeholder "exit country (type to search)" ) || continue
        set_region "$( [ "$pick" = "best available" ] && echo best || echo "$pick" )" >/dev/null ;;
      Mode*)
        local m
        m=$(gum choose --header "Mode" "vpn -- whole system (TCP only, UDP blocked)" "proxy -- only apps set to use $SOCKS") || continue
        set_mode "${m%% *}" >/dev/null ;;
      "Check my IP") clear; gum spin --title "Asking..." --show-output -- bash -c "$(declare -f is_on show_ip); SOCKS=$SOCKS show_ip"
                     echo; gum input --placeholder "Enter to go back" >/dev/null || true ;;
      Log)     clear; follow_log || sleep 2 ;;
      Refresh) ;;
      Quit)    return 0 ;;
    esac
  done
}

# --- dispatch ---------------------------------------------------------------
case "${1:-}" in
  "")       if [ -t 0 ] && [ -t 1 ]; then tui; else status_lines; fi ;;
  tui)      tui ;;
  status)   status_lines ;;
  on)       turn_on ;;
  off)      turn_off ;;
  toggle)   if is_on; then turn_off; else turn_on; fi ;;
  region)   if [ -n "${2:-}" ]; then set_region "$2"; else
              echo "available: best $(regions)"; echo "set with: psiphon region <CC>"; fi ;;
  mode)     set_mode "${2:-}" ;;
  ip)       show_ip ;;
  log|logs) follow_log ;;
  -h|--help|help) usage ;;
  *)        usage >&2; exit 2 ;;
esac
