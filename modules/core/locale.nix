# =============================================================================
# Locale  --  time zone, language, keyboard
# =============================================================================
#
# Set with lib.mkDefault so a host or profile can override any of it without
# an "option defined twice" error. A plain assignment would conflict; mkDefault
# means "use this unless someone says otherwise".
# =============================================================================
{
  flake.nixosModules.coreLocale =
    { lib, ... }:
    {
      time.timeZone = lib.mkDefault "Asia/Kolkata";

      # Interface language is British English; the LC_* values below keep
      # dates, paper size and number formatting Indian.
      i18n.defaultLocale = lib.mkDefault "en_GB.UTF-8";

      i18n.extraLocaleSettings = {
        LC_ADDRESS = "en_IN";
        LC_IDENTIFICATION = "en_IN";
        LC_MEASUREMENT = "en_IN";
        LC_MONETARY = "en_IN";
        LC_NAME = "en_IN";
        LC_NUMERIC = "en_IN";
        LC_PAPER = "en_IN";
        LC_TELEPHONE = "en_IN";
        LC_TIME = "en_IN";
      };

      # Keyboard layout for the text consoles (Ctrl+Alt+F2 and friends).
      # The graphical layout is set per-profile in the niri settings.
      console.keyMap = "us";
    };
}
