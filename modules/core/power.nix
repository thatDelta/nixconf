# =============================================================================
# Power  --  suspend, lid switch, battery
# =============================================================================
#
# FIXES THE "SLEEP DOESN'T WORK" PROBLEM
#
#   Symptom: closing the lid or leaving the machine idle did nothing, even
#   with noctalia's caffeine/idle-inhibit toggle turned off.
#
#   Cause: there were TWO separate things missing, which is why turning off
#   caffeinate alone never helped.
#
#     1. Nothing was configured to ASK for sleep. logind (the systemd service
#        that watches the lid and power button) had no instructions, so
#        closing the lid was simply an event nobody acted on. Turning off an
#        inhibitor does not help when there is no request to inhibit.
#
#     2. Nothing was configured to ALLOW sleep either -- systemd's sleep
#        settings were at their defaults.
#
#   Fix: logind below says what should happen (lid closed -> suspend), and
#   systemd.sleep says suspend is permitted.
#
#   NOTE: idle timeout (sleep after N minutes of no input) is a separate
#   thing again, and it belongs to the desktop shell rather than the system.
#   That one lives in the noctalia settings -- see modules/features/noctalia.json,
#   the "idle" section.
# =============================================================================
{
  flake.nixosModules.corePower = {

    services.logind.settings.Login = {
      # What the physical power button does.
      powerKey = "suspend";

      # Closing the lid on battery suspends.
      lidSwitch = "suspend";

      # Closing the lid while plugged in only locks -- so a download or build
      # can keep running with the lid shut.
      lidSwitchExternalPower = "lock";
    };

    # --- hibernation -------------------------------------------------------
    # Hibernation writes RAM to disk and powers off completely, then restores
    # the session on next boot. It needs two things, and BOTH must be right --
    # with only the first, hibernating appears to work and then boots to a
    # blank session, losing everything.
    #
    #   1. swap at least as large as RAM, to hold the image
    #      this machine: 23G RAM, 25.5G swap partition -- fine
    #   2. the kernel must be told which device holds that image on resume
    #      that is boot.resumeDevice below; without it there is no `resume=`
    #      kernel parameter and the image is never read back
    #
    # (zram is also enabled, in core/boot.nix. It is compressed swap living in
    # RAM, at a higher priority so it gets used first for ordinary swapping.
    # It cannot hold a hibernation image -- that is what the real partition
    # below is for. The two coexist fine.)
    boot.resumeDevice = "/dev/disk/by-uuid/0e88a101-e9da-47bc-8a25-cb6fe658bc9b";

    systemd.sleep.settings.Sleep = {
      AllowSuspend = true;
      AllowHibernation = true;

      # Suspend first, then hibernate after the delay below. This is the good
      # laptop default: instant wake if you come back soon, no flat battery if
      # you leave it in a bag for two days.
      AllowSuspendThenHibernate = true;
      HibernateDelaySec = "30min";

      # Hybrid sleep writes the image AND stays suspended, so a power loss
      # while asleep does not lose the session. It makes every suspend slower,
      # which is why suspend-then-hibernate above is usually the better trade.
      AllowHybridSleep = false;
    };

    # Battery percentage, "low battery" warnings, and the battery readout in
    # the bar all come from upower.
    services.upower = {
      enable = true;
      percentageLow = 20;
      percentageCritical = 10;
      percentageAction = 5;
      # At 5% battery, hibernate rather than power off: the session is written
      # to disk and comes back when you plug in, instead of being lost.
      criticalPowerAction = "Hibernate";
    };

    # Lets you switch between power-saver / balanced / performance, which the
    # noctalia bar exposes as a toggle.
    services.power-profiles-daemon.enable = true;
  };
}
