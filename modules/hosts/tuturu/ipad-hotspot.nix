# =============================================================================
# ipad-hotspot  --  the laptop hosts a hotspot for the iPad, ON DEMAND
# =============================================================================
#
# WHY
#   Streaming through the phone's hotspot sends every frame over the air
#   twice (laptop -> phone -> iPad), on the same channel, so the two hops
#   take turns. With the laptop as the hotspot it is one hop.
#
# HOW: TWO INTERFACES ON ONE CARD
#   The Realtek RTL8852BE allows, at the same time (`iw list`):
#     #{ managed } <= 1, #{ AP, ... } <= 1, #channels <= 1
#   So wlp1s0 stays the normal Wi-Fi client (internet), and a second
#   virtual interface, ap0, is a true AP-mode interface for the hotspot.
#   hostapd runs the AP, dnsmasq hands out addresses. (NetworkManager can't
#   do this: its hotspots need a second "managed" interface, which the card
#   doesn't allow.)
#
# THE CATCH: "#channels <= 1"  --  why this is OFF until you turn it on
#   The card can only be on one channel. While the hotspot runs, wlp1s0 can
#   only join networks on the hotspot's channel -- an always-on hotspot on
#   5 GHz made a phone hotspot on 2.4 GHz "not found". So:
#     - nothing here starts at boot;
#     - on start, the hotspot copies whatever channel wlp1s0 is on right
#       now (5 GHz: 80 MHz wide; 2.4 GHz: 20 MHz, slower but works);
#     - connect to your Wi-Fi FIRST, then turn the hotspot on. If you
#       switch Wi-Fi networks, toggle the hotspot off and on again.
#
# TURN IT ON/OFF: the hotspot button in noctalia's control centre, or
#   `tuturu-ctl toggle hotspot` (see toggles.nix).
#
# ONE-TIME SETUP -- the password lives outside the repo:
#   sudo mkdir -p /var/lib/ipad-hotspot
#   echo 'CHOOSE-A-PASSWORD' | sudo tee /var/lib/ipad-hotspot/password >/dev/null
#   sudo chmod 600 /var/lib/ipad-hotspot/password
#
# ON THE IPAD: join "tuturu-ipad". The laptop is 10.42.0.1 (add it in
# Moonlight manually by that IP if it isn't discovered).
#
# TO DISCARD: delete this file and its line in configuration.nix.
# =============================================================================
{ ... }:
{
  flake.nixosModules.tuturuIpadHotspot =
    { pkgs, lib, ... }:
    let
      # Writes /run/ipad-hotspot/hostapd.conf for wlp1s0's current channel.
      makeConfig = pkgs.writeShellApplication {
        name = "ipad-hotspot-config";
        runtimeInputs = [ pkgs.iw pkgs.gawk pkgs.coreutils ];
        text = ''
          ch=$(iw dev wlp1s0 info | awk '/channel/ { print $2; exit }')
          ch=''${ch:-149}   # not connected to anything: a free 5 GHz channel

          if (( ch >= 52 && ch <= 144 )); then
            echo "wlp1s0 is on channel $ch, a radar (DFS) channel the hotspot can't use." >&2
            exit 1
          fi

          {
            echo "interface=ap0"
            echo "driver=nl80211"
            echo "ctrl_interface=/run/hostapd"
            echo "ssid=tuturu-ipad"
            echo "country_code=IN"
            echo "ieee80211d=1"
            echo "channel=$ch"
            echo "wmm_enabled=1"
            echo "ieee80211n=1"
            if (( ch <= 14 )); then
              echo "hw_mode=g"
              echo "ht_capab=[SHORT-GI-20]"
            else
              # Pair the channel with its neighbour for 40 MHz, then pick the
              # 80 MHz block it sits in (149-161 is centred on 155, and so on).
              if (( ch >= 149 )); then base=149; else base=36; fi
              if (( (ch - base) / 4 % 2 == 0 )); then ht="HT40+"; else ht="HT40-"; fi
              if (( ch >= 149 )); then centre=155; else centre=$(( 36 + (ch - 36) / 16 * 16 + 6 )); fi
              echo "hw_mode=a"
              echo "ht_capab=[$ht][SHORT-GI-20][SHORT-GI-40]"
              echo "ieee80211ac=1"
              echo "vht_capab=[SHORT-GI-80]"
              echo "vht_oper_chwidth=1"
              echo "vht_oper_centr_freq_seg0_idx=$centre"
            fi
            echo "wpa=2"
            echo "wpa_key_mgmt=SAE"
            echo "rsn_pairwise=CCMP"
            echo "ieee80211w=2"
            echo "sae_password=$(cat /var/lib/ipad-hotspot/password)"
          } > /run/ipad-hotspot/hostapd.conf
        '';
      };
    in
    {
      # The whole hotspot is this one service: create ap0, write the config,
      # run hostapd; on stop, ap0 is deleted again. No wantedBy -- it only
      # runs when started by hand.
      systemd.services.ipad-hotspot = {
        description = "Wi-Fi hotspot for the iPad (ap0)";
        after = [ "sys-subsystem-net-devices-wlp1s0.device" ];
        bindsTo = [ "sys-subsystem-net-devices-wlp1s0.device" ];
        wants = [ "dnsmasq.service" ];
        path = [ pkgs.iw pkgs.iproute2 ];
        serviceConfig = {
          RuntimeDirectory = "ipad-hotspot";
          ExecStartPre = [
            "-${pkgs.iw}/bin/iw dev ap0 del"
            "${pkgs.iw}/bin/iw dev wlp1s0 interface add ap0 type __ap"
            # The card's MAC with the "locally administered" bit set, so the
            # two interfaces don't share an address.
            "${pkgs.iproute2}/bin/ip link set ap0 address ea:65:38:3e:63:29"
            "${makeConfig}/bin/ipad-hotspot-config"
          ];
          ExecStart = "${pkgs.hostapd}/bin/hostapd /run/ipad-hotspot/hostapd.conf";
          # hostapd brings ap0 up; the address can only be added after that.
          ExecStartPost = "${pkgs.bash}/bin/sh -c 'sleep 1; ip addr replace 10.42.0.1/24 dev ap0'";
          ExecStopPost = "-${pkgs.iw}/bin/iw dev ap0 del";
        };
      };

      # Keeps NetworkManager (and the wpa_supplicant it drives) off ap0.
      networking.networkmanager.unmanaged = [ "interface-name:ap0" ];

      # --- addresses for the iPad -----------------------------------------
      # Only a DHCP server for ap0 -- not this machine's DNS resolver
      # (core/network.nix points that at Cloudflare and must stay so).
      # Started and stopped together with the hotspot.
      services.dnsmasq = {
        enable = true;
        resolveLocalQueries = false;
        settings = {
          interface = "ap0";
          bind-dynamic = true;
          port = 0; # DNS off; DHCP only
          dhcp-range = [ "10.42.0.10,10.42.0.100,12h" ];
          dhcp-option = [ "option:dns-server,1.1.1.1" ];
        };
      };
      systemd.services.dnsmasq = {
        wantedBy = lib.mkForce [ ];
        partOf = [ "ipad-hotspot.service" ];
        after = [ "ipad-hotspot.service" ];
      };

      # Give the iPad internet through whatever wlp1s0 is connected to.
      networking.nat = {
        enable = true;
        internalInterfaces = [ "ap0" ];
        externalInterface = "wlp1s0";
      };

      # DHCP requests and Sunshine/Moonlight discovery arrive on ap0.
      networking.firewall.trustedInterfaces = [ "ap0" ];

      # Wi-Fi power saving (on in core/network.nix for battery) makes the
      # card doze between packets: harmless for browsing, visible as
      # stutter in a 60 fps stream. Off on this machine.
      networking.networkmanager.wifi.powersave = lib.mkForce false;
    };
}
