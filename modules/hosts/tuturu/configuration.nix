{ self, inputs, ... }: {

  flake.nixosModules.tuturuConfiguration = # Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      self.nixosModules.tuturuHardware
      self.nixosModules.niri
      self.nixosModules.homeManager
      self.nixosModules.yume
      inputs.silentSDDM.nixosModules.default
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "tuturu"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Asia/Kolkata";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.UTF-8";

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

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the SDDM display manager for Wayland.
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = lib.mkForce true;

  # SilentSDDM theme (Rei preset) via the official NixOS flake module
  programs.silentSDDM = {
    enable = true;
    theme = "rei";
  };

  # In the VM, use GDM so we can actually log in and test Niri/noctalia
  virtualisation.vmVariant = {
    services.displayManager.sddm.enable = lib.mkForce false;
    services.xserver.displayManager.gdm.enable = lib.mkForce true;
    users.users.delta.initialPassword = lib.mkForce "nixos";
  };

  environment.systemPackages = with pkgs; [
    inputs.sidra.packages.${pkgs.system}.default
    inputs.antigravity-nix.packages.${pkgs.system}.google-antigravity-ide
    git
  ];

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."delta" = {
    isNormalUser = true;
    description = "delta";
    shell = pkgs.fish;
    extraGroups = [ "networkmanager" "wheel" "wireshark" "adbusers" "input" "video" "audio" ];
    packages = with pkgs; [
    #  thunderbird
    ];
  };

  # Register Niri as a wayland session so GDM shows it
  xdg.portal.enable = true;
  environment.etc."wayland-sessions/niri.desktop".text = ''
    [Desktop Entry]
    Name=Niri
    Comment=A scrollable-tiling Wayland compositor
    Exec=noctalia-shell
    Type=Application
  '';

  # Install firefox.
  programs.firefox.enable = true;

  # Enable shells
  programs.fish.enable = true;
  programs.zsh.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  # Packages were moved up to accommodate SDDM theme derivation.

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05"; # Did you read the comment?
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    extra-substituters = [ "https://cache.numtide.com" ];
    extra-trusted-public-keys = [ "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=" ];
  };
};

}
