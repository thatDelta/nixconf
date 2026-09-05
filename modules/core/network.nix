# =============================================================================
# Network  --  NetworkManager, DNS, and the secret agent wifi needs
# =============================================================================
#
# FIXES THE "WIFI IN THE TOP BAR DOESN'T WORK LIKE nmtui" PROBLEM
#
#   Symptom: the noctalia bar's wifi menu kept asking you to set up a network,
#   often failed to connect, and behaved as if it had never seen your saved
#   networks -- while `nmtui` in a terminal worked fine.
#
#   Cause: both talk to the same NetworkManager daemon, but they store and
#   retrieve wifi PASSWORDS differently.
#     - nmtui runs in your terminal and can prompt you directly, then hands
#       the password straight to NetworkManager.
#     - A graphical client cannot prompt like that. It expects a running
#       "secret agent" -- a background service that holds saved secrets and
#       answers when NetworkManager asks for them. There was no secret agent
#       on this system, so every graphical connection attempt behaved like a
#       brand new one with no stored password.
#
#   Fix: gnome-keyring below is that secret agent. gcr/libsecret are the
#   libraries clients use to talk to it. This is exactly what shin does.
# =============================================================================
{
  flake.nixosModules.coreNetwork =
    { pkgs, ... }:
    {
      networking = {
        networkmanager = {
          enable = true;

          # Let NetworkManager own resolv.conf rather than fighting with it,
          # but point it at Cloudflare instead of whatever the cafe hands out.
          dns = "none";

          # Saves a meaningful amount of battery on a laptop. If you ever see
          # wifi drop when idle, this is the first thing to turn off.
          wifi.powersave = true;
        };

        nameservers = [ "1.1.1.1" "1.0.0.1" ];

        # NetworkManager handles addressing; the legacy DHCP clients would
        # only race it.
        useDHCP = false;
        dhcpcd.enable = false;
      };

      # --- the secret agent (see the note at the top of this file) ----------
      services.gnome.gnome-keyring.enable = true;

      services.dbus.packages = with pkgs; [
        gcr        # prompts for unlocking the keyring
        libsecret  # client library apps use to read/write secrets
      ];

      # Unlock the keyring automatically when you log in, so you are not typing
      # a second password just to get wifi back after boot.
      security.pam.services.sddm.enableGnomeKeyring = true;

      # Boot does not need to block waiting for a network to appear.
      systemd.services.NetworkManager-wait-online.enable = false;
    };
}
