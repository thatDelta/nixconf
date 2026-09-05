# =============================================================================
# Audio  --  PipeWire
# =============================================================================
{
  flake.nixosModules.coreAudio = {

    # PipeWire is the modern audio server. It replaces PulseAudio and JACK
    # while still pretending to be both, so apps written for either still work.
    services.pipewire = {
      enable = true;

      alsa.enable = true;
      alsa.support32Bit = true;

      # Presents a PulseAudio interface. Most applications still ask for
      # PulseAudio, so leaving this off means "no sound" in a lot of places.
      pulse.enable = true;
    };

    # The old PulseAudio server must be off, or the two fight over the sound
    # card and neither wins.
    services.pulseaudio.enable = false;

    # Lets PipeWire request realtime priority, which is what prevents crackling
    # under load.
    security.rtkit.enable = true;
  };
}
