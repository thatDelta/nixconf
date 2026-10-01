# =============================================================================
# ipad-hotspot  --  the laptop hosts a 5 GHz hotspot for the iPad directly
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
#
#   NetworkManager can NOT run this hotspot: it starts hotspots through
#   wpa_supplicant, which needs a "managed" interface -- and the card only
#   allows one of those (wlp1s0). Tried; it fails with "wpa_supplicant
#   couldn't grab this interface". So hostapd runs the AP, dnsmasq hands
#   out addresses, and NetworkManager is told to leave ap0 alone.
#
# THE CATCH: "#channels <= 1"
#   The hotspot must sit on the SAME channel as whatever wlp1s0 is joined
#   to (your phone's hotspot was on 149 / 80 MHz when this was written).
#   If hostapd fails to start, check `iw dev` for wlp1s0's channel and
#   change `channel` (and the centre index) below to match.
#
# ONE-TIME SETUP -- the password lives outside the repo:
#   sudo mkdir -p /var/lib/ipad-hotspot
#   echo 'CHOOSE-A-PASSWORD' | sudo tee /var/lib/ipad-hotspot/password >/dev/null
#   sudo chmod 600 /var/lib/ipad-hotspot/password
#   sudo systemctl restart hostapd
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
    {
      # Create ap0 next to wlp1s0, in AP mode from the start. The MAC is the
      # card's own with the "locally administered" bit set, so the two
      # interfaces don't share an address.
      systemd.services.wifi-ap0 = {
        description = "Virtual AP interface for the iPad hotspot";
        after = [ "sys-subsystem-net-devices-wlp1s0.device" ];
        bindsTo = [ "sys-subsystem-net-devices-wlp1s0.device" ];
        before = [ "hostapd.service" ];
        wantedBy = [ "multi-user.target" ];
        path = [ pkgs.iw pkgs.iproute2 ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          iw dev ap0 del 2>/dev/null || true
          iw dev wlp1s0 interface add ap0 type __ap
          ip link set ap0 address ea:65:38:3e:63:29
        '';
        preStop = "iw dev ap0 del || true";
      };

      # Keeps NetworkManager (and the wpa_supplicant it drives) off ap0.
      #
      # Rebuilds print "Some wireless interface is configured for both for
      # client and access point mode". That check fires whenever
      # wpa_supplicant is enabled without an explicit interface list; under
      # NetworkManager it only grabs interfaces NM hands it, and this line
      # excludes ap0. Harmless -- do not "fix" it by pinning
      # networking.wireless.interfaces, which would fight NetworkManager.
      networking.networkmanager.unmanaged = [ "interface-name:ap0" ];

      # --- the access point -------------------------------------------------
      services.hostapd = {
        enable = true;
        radios.ap0 = {
          band = "5g";
          channel = 149;
          countryCode = "IN";
          wifi4.capabilities = [ "HT40+" "SHORT-GI-20" "SHORT-GI-40" ];
          wifi5 = {
            operatingChannelWidth = "80";
            capabilities = [ "SHORT-GI-80" ];
          };
          # 80 MHz block starting at channel 149 is centred on 155.
          settings.vht_oper_centr_freq_seg0_idx = 155;

          networks.ap0 = {
            ssid = "tuturu-ipad";
            authentication = {
              mode = "wpa3-sae";
              saePasswordsFile = "/var/lib/ipad-hotspot/password";
            };
          };
        };
      };

      # --- addresses for the iPad -----------------------------------------
      networking.interfaces.ap0.ipv4.addresses = [
        { address = "10.42.0.1"; prefixLength = 24; }
      ];

      services.dnsmasq = {
        enable = true;
        # Only a DHCP server for ap0 -- not this machine's DNS resolver
        # (core/network.nix points that at Cloudflare and must stay so).
        resolveLocalQueries = false;
        settings = {
          interface = "ap0";
          bind-dynamic = true;
          port = 0; # DNS off; DHCP only
          dhcp-range = [ "10.42.0.10,10.42.0.100,12h" ];
          dhcp-option = [ "option:dns-server,1.1.1.1" ];
        };
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
