# =============================================================================
# Keyring  --  where saved passwords live
# =============================================================================
#
# WHAT A KEYRING IS
#   An encrypted store for secrets, unlocked once when you log in. Programs
#   ask a "Secret Service" over D-Bus for their saved tokens instead of each
#   one inventing its own storage.
#
# WHAT BREAKS WITHOUT IT
#   Two things you have already hit:
#     - wifi: graphical network clients have nowhere to save the password, so
#       every connection behaves like a first-time one (nmtui works, because
#       it can prompt you in the terminal instead).
#     - apps: anything storing a login token -- Claude Desktop, browsers,
#       git credential helpers -- has nowhere to persist it, so you sign in
#       again after every restart.
#
# HOW THE PIECES FIT
#   gnome-keyring      the daemon that holds the secrets
#   gcr / libsecret    the libraries apps use to talk to it
#   PAM                unlocks the keyring with your login password, so you
#                      are not asked for a second password at every boot
# =============================================================================
{
  flake.nixosModules.coreKeyring =
    { pkgs, ... }:
    {
      services.gnome.gnome-keyring.enable = true;

      services.dbus.packages = with pkgs; [
        gcr        # the "unlock your keyring" prompt
        libsecret  # the client library apps link against
      ];

      # --- unlocking on login ------------------------------------------------
      # Without these the keyring exists but stays LOCKED until something asks
      # for a password, which is the state where apps appear to "forget" their
      # logins even though the secrets are safely stored.
      #
      # sddm  = the graphical login you actually use
      # login = text console login (Ctrl+Alt+F2), so it works there too
      security.pam.services.sddm.enableGnomeKeyring = true;
      security.pam.services.login.enableGnomeKeyring = true;

      # Electron apps (Claude Desktop among them) and GTK apps read settings
      # through dconf; without it they fall back to defaults every start.
      programs.dconf.enable = true;

      # The command-line tool for inspecting the keyring, for when you want to
      # check whether something actually got saved:
      #     secret-tool search --all service <name>
      environment.systemPackages = [ pkgs.libsecret ];
    };
}
