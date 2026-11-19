# =============================================================================
# Psiphon  --  censorship-circumvention VPN for the WHOLE machine, on demand
# =============================================================================
#
# HOW IT WORKS (two services)
#   psiphon       Psiphon's "tunnel core": connects to the Psiphon network and
#                 exposes a local SOCKS proxy on 127.0.0.1:1081 (and HTTP on
#                 8081). On its own that only helps apps you point at it.
#   psiphon-tun   sing-box, creating a virtual network card (psiphon0) and
#                 routing EVERY packet on the machine into that SOCKS proxy.
#                 That is what makes it a whole-system VPN.
#   Starting psiphon starts psiphon-tun with it; stopping it stops both.
#
#   The loop problem: psiphon's OWN traffic must not go into the tunnel it is
#   providing. So it runs as its own system user (uid 2391) and sing-box
#   leaves that uid's traffic alone (exclude_uid).
#
# WHAT STAYS DIRECT (not tunnelled)
#   LAN / iPad hotspot / Tailscale addresses (route_exclude_address below),
#   so Sunshine, Jellyfin and local devices keep working while it is on.
#
# LIMITATION: TCP only
#   Psiphon's SOCKS proxy carries TCP, not UDP. DNS is handled inside the
#   tunnel (sent as TCP through Psiphon), other UDP is rejected -- browsers
#   fall back from QUIC to normal HTTPS automatically. UDP-only things
#   (some games, WireGuard) won't work while it is on.
#
# HOW TO RUN IT
#   psiphon                            terminal menu: on/off, region, mode, IP, log
#   psiphon on|off|status|region CC|mode vpn|proxy|ip    same, as plain commands
#   Mod+D -> "Psiphon"                 opens the menu in a kitty window
#   tuturu-ctl on|off|toggle psiphon
#   journalctl -u psiphon -u psiphon-tun -f     watch it connect
#   curl https://api.ipify.org                  should show a different IP
#
# WHERE THE PIECES COME FROM
#   binary  Psiphon-Labs/psiphon-tunnel-core-binaries, pinned to a commit.
#           To update: bump `rev`, set hash = "", rebuild, paste the hash the
#           error prints.
#   config  the public client config used by SpherionOS/PsiphonLinux (the
#           usual "Psiphon on Linux" recipe). The signature key is what lets
#           the client verify the server list it downloads is genuine.
#   state   /var/lib/psiphon -- server list and connection cache.
#   yours   /var/lib/psiphon-settings/settings.json -- region + mode, edited
#           by the `psiphon` command (see psiphon-tui.sh).
# =============================================================================
{ ... }:
{
  flake.nixosModules.psiphon =
    { pkgs, lib, config, ... }:
    let
      rev = "33ff79e89260f3adf92e846b96b3369b86a819d8";
      uid = 2391;

      psiphon = pkgs.stdenv.mkDerivation {
        pname = "psiphon-tunnel-core";
        version = "unstable-2026-10-05";
        src = pkgs.fetchurl {
          url = "https://raw.githubusercontent.com/Psiphon-Labs/psiphon-tunnel-core-binaries/${rev}/linux/psiphon-tunnel-core-x86_64";
          hash = "sha256-BGyhaNol0sDmHBwV4rc7+7Z/UggRKkyU/lj8Wqt4Txk=";
        };
        dontUnpack = true;
        # The upstream binary is UPX-packed and expects /lib64/ld-linux, which
        # NixOS does not have (under systemd it hit the stub loader and
        # segfaulted). Unpack it, then point it at nix's glibc.
        nativeBuildInputs = [ pkgs.upx pkgs.autoPatchelfHook ];
        installPhase = ''
          install -Dm755 $src $out/bin/psiphon-tunnel-core
          upx -d $out/bin/psiphon-tunnel-core
        '';
        meta = {
          description = "Psiphon tunnel core (local HTTP/SOCKS proxy)";
          homepage = "https://github.com/Psiphon-Labs/psiphon-tunnel-core";
          platforms = [ "x86_64-linux" ];
          sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
          mainProgram = "psiphon-tunnel-core";
        };
      };

      psiphonConfig = pkgs.writeText "psiphon.config" (builtins.toJSON {
        LocalHttpProxyPort = 8081;
        LocalSocksProxyPort = 1081;
        PropagationChannelId = "FFFFFFFFFFFFFFFF";
        SponsorId = "FFFFFFFFFFFFFFFF";
        RemoteServerListDownloadFilename = "remote_server_list";
        RemoteServerListUrl = "https://s3.amazonaws.com//psiphon/web/mjr4-p23r-puwl/server_list_compressed";
        RemoteServerListSignaturePublicKey = "MIICIDANBgkqhkiG9w0BAQEFAAOCAg0AMIICCAKCAgEAt7Ls+/39r+T6zNW7GiVpJfzq/xvL9SBH5rIFnk0RXYEYavax3WS6HOD35eTAqn8AniOwiH+DOkvgSKF2caqk/y1dfq47Pdymtwzp9ikpB1C5OfAysXzBiwVJlCdajBKvBZDerV1cMvRzCKvKwRmvDmHgphQQ7WfXIGbRbmmk6opMBh3roE42KcotLFtqp0RRwLtcBRNtCdsrVsjiI1Lqz/lH+T61sGjSjQ3CHMuZYSQJZo/KrvzgQXpkaCTdbObxHqb6/+i1qaVOfEsvjoiyzTxJADvSytVtcTjijhPEV6XskJVHE1Zgl+7rATr/pDQkw6DPCNBS1+Y6fy7GstZALQXwEDN/qhQI9kWkHijT8ns+i1vGg00Mk/6J75arLhqcodWsdeG/M/moWgqQAnlZAGVtJI1OgeF5fsPpXu4kctOfuZlGjVZXQNW34aOzm8r8S0eVZitPlbhcPiR4gT/aSMz/wd8lZlzZYsje/Jr8u/YtlwjjreZrGRmG8KMOzukV3lLmMppXFMvl4bxv6YFEmIuTsOhbLTwFgh7KYNjodLj/LsqRVfwz31PgWQFTEPICV7GCvgVlPRxnofqKSjgTWI4mxDhBpVcATvaoBl1L/6WLbFvBsoAUBItWwctO2xalKxF5szhGm8lccoc5MZr8kfE0uxMgsxz4er68iCID+rsCAQM=";
        UseIndistinguishableTLS = true;
        # No EgressRegion: let Psiphon pick whichever server works best.
      });

      # sing-box: the TUN device that turns the SOCKS proxy into a VPN.
      tunConfig = pkgs.writeText "psiphon-tun.json" (builtins.toJSON {
        log.level = "warn";
        dns = {
          servers = [
            # DNS goes through Psiphon too (as TCP), so lookups aren't
            # visible to / blockable by the local network.
            { type = "tcp"; tag = "remote"; server = "1.1.1.1"; detour = "psiphon"; }
          ];
          final = "remote";
        };
        inbounds = [{
          type = "tun";
          tag = "tun-in";
          interface_name = "psiphon0";
          address = [ "198.18.0.1/30" "fdfe:dcba:9876::1/126" ];
          auto_route = true;
          strict_route = true;
          exclude_uid = [ uid ];            # psiphon's own connections
          route_exclude_address = [
            "10.0.0.0/8" "172.16.0.0/12" "192.168.0.0/16"   # LAN, iPad hotspot
            "100.64.0.0/10"                                  # Tailscale
            "169.254.0.0/16" "fc00::/7" "fe80::/10"
          ];
        }];
        outbounds = [
          { type = "socks"; tag = "psiphon"; server = "127.0.0.1"; server_port = 1081; version = "5"; }
        ];
        route = {
          auto_detect_interface = true;
          rules = [
            { action = "sniff"; }
            { protocol = "dns"; action = "hijack-dns"; }
            { network = "udp"; action = "reject"; }   # Psiphon can't carry UDP
          ];
          final = "psiphon";
        };
      });

      # Settings you change at runtime (region, mode) -- owned by you, so the
      # `psiphon` command edits them without sudo. Read on every start.
      settings = "/var/lib/psiphon-settings/settings.json";
      jq = lib.getExe pkgs.jq;

      # Builds the real config from the fixed one above + your settings, then
      # runs Psiphon. Its notices (JSON lines: connected, server region, ...)
      # also go to /run/psiphon/notices.jsonl, which is what `psiphon status`
      # reads -- cleared each time it stops.
      start = pkgs.writeShellScript "psiphon-start" ''
        set -eu
        cfg=/run/psiphon/config.json
        region=$(${jq} -r '.region // ""' ${settings} 2>/dev/null || true)
        if [ -n "$region" ]; then
          ${jq} --arg r "$region" '.EgressRegion = $r' ${psiphonConfig} > "$cfg"
        else
          cat ${psiphonConfig} > "$cfg"
        fi
        exec ${lib.getExe psiphon} -config "$cfg" -dataRootDirectory /var/lib/psiphon \
          2> >(tee -a /run/psiphon/notices.jsonl >&2)
      '';

      # psiphon-tun only comes up in VPN mode; in proxy mode it is skipped.
      isVpnMode = pkgs.writeShellScript "psiphon-is-vpn-mode" ''
        [ "$(${jq} -r '.mode // "vpn"' ${settings} 2>/dev/null || echo vpn)" = vpn ]
      '';

      # Psiphon has no official Linux GUI; this is the control panel instead:
      # `psiphon` opens a terminal menu, `psiphon on|off|region ...` is the CLI.
      # The script is modules/features/psiphon-tui.sh.
      cli = pkgs.writeShellApplication {
        name = "psiphon";
        runtimeInputs = with pkgs; [ gum jq curl systemd libnotify coreutils gnugrep ];
        text = builtins.readFile ./psiphon-tui.sh;
      };

      launcher = pkgs.makeDesktopItem {
        name = "psiphon";
        desktopName = "Psiphon";
        comment = "Psiphon VPN: on/off, region, mode";
        exec = "kitty --class psiphon --title Psiphon -e psiphon";
        icon = "network-vpn";
        categories = [ "Network" ];
      };
    in
    {
      environment.systemPackages = [ psiphon cli launcher ];

      users.users.psiphon = {
        inherit uid;
        isSystemUser = true;
        group = "psiphon";
      };
      users.groups.psiphon = { };

      systemd.tmpfiles.rules = [
        "d /var/lib/psiphon-settings 0755 ${config.my.username} users -"
      ];

      systemd.services.psiphon = {
        description = "Psiphon tunnel core (SOCKS 1081, HTTP 8081)";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" "psiphon-tun.service" ];
        serviceConfig = {
          User = "psiphon";
          Group = "psiphon";
          StateDirectory = "psiphon";
          RuntimeDirectory = "psiphon";
          RuntimeDirectoryMode = "0755";   # so `psiphon status` can read notices
          ExecStart = start;
          Restart = "on-failure";
          RestartSec = 5;
        };
        # Deliberately no wantedBy: it starts only when you ask for it.
      };

      systemd.services.psiphon-tun = {
        description = "Route all traffic through Psiphon (sing-box TUN)";
        after = [ "psiphon.service" ];
        bindsTo = [ "psiphon.service" ];   # psiphon stops -> this stops
        serviceConfig = {
          ExecCondition = isVpnMode;
          ExecStart = "${lib.getExe pkgs.sing-box} run -c ${tunConfig} -D /var/lib/psiphon-tun";
          StateDirectory = "psiphon-tun";
          Restart = "on-failure";
          RestartSec = 3;
        };
      };

      # Policy routing through a TUN trips strict reverse-path filtering.
      networking.firewall.checkReversePath = "loose";
      networking.firewall.trustedInterfaces = [ "psiphon0" ];

      # Let your user start/stop/restart these two without a password prompt.
      security.polkit.extraConfig = ''
        polkit.addRule(function (action, subject) {
          var units = ["psiphon.service", "psiphon-tun.service"];
          if (action.id == "org.freedesktop.systemd1.manage-units" &&
              subject.user == "${config.my.username}" &&
              units.indexOf(action.lookup("unit")) >= 0) {
            return polkit.Result.YES;
          }
        });
      '';
    };
}
