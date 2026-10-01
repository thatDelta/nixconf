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
#   The Realtek RTL8852BE can be a normal Wi-Fi client AND an access point at
#   the same time (`iw list`: "#{ managed } <= 1, #{ AP, ... } <= 1,
#   #channels <= 1"). So wlp1s0 stays connected to whatever gives you
#   internet, and a second virtual interface, ap0, hosts the hotspot.
#   The catch is "#channels <= 1": both must sit on the SAME channel. If
#   the hotspot refuses to start, the network wlp1s0 is on has moved
#   channel -- check with `iw dev` and change the profile's channel.
#
# ONE-TIME SETUP (kept out of the repo so the password isn't in git):
#   nmcli con add type wifi ifname ap0 con-name ipad-hotspot \
#     ssid tuturu-ipad mode ap 802-11-wireless.band a \
#     802-11-wireless.channel 149 ipv4.method shared \
#     wifi-sec.key-mgmt wpa-psk wifi-sec.psk 'CHOOSE-A-PASSWORD'
#   then `nmcli con up ipad-hotspot` whenever you want it
#   (`nmcli con modify ipad-hotspot connection.autoconnect yes` to always).
#   `ipv4.method shared` = NetworkManager runs DHCP/DNS for the iPad and
#   NATs its traffic out through wlp1s0.
#
# TO DISCARD: delete this file and its line in configuration.nix, then
# `nmcli con delete ipad-hotspot`.
# =============================================================================
{ ... }:
{
  flake.nixosModules.tuturuIpadHotspot =
    { pkgs, lib, ... }:
    {
      # Create ap0 alongside wlp1s0 once the card shows up. It is created as
      # a plain "managed" interface on purpose: NetworkManager starts the
      # hotspot through wpa_supplicant, which flips it into AP mode itself;
      # created as type __ap (the hostapd recipe) NM just marks it
      # "unavailable". The MAC is the
      # card's own with the "locally administered" bit set, so the two
      # interfaces don't share an address.
      systemd.services.wifi-ap0 = {
        description = "Virtual AP interface for the iPad hotspot";
        after = [ "sys-subsystem-net-devices-wlp1s0.device" ];
        bindsTo = [ "sys-subsystem-net-devices-wlp1s0.device" ];
        wantedBy = [ "multi-user.target" ];
        path = [ pkgs.iw pkgs.iproute2 ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          iw dev ap0 info >/dev/null 2>&1 || iw dev wlp1s0 interface add ap0 type managed
          ip link set ap0 address ea:65:38:3e:63:29
        '';
        preStop = "iw dev ap0 del || true";
      };

      # The iPad must reach NetworkManager's DHCP/DNS (dnsmasq) on ap0, and
      # Sunshine/Moonlight discovery -- trust the hotspot's own interface.
      networking.firewall.trustedInterfaces = [ "ap0" ];

      # Wi-Fi power saving (on in core/network.nix for battery) makes the
      # card doze between packets: harmless for browsing, visible as
      # stutter in a 60 fps stream. Off on this machine.
      networking.networkmanager.wifi.powersave = lib.mkForce false;
    };
}
