{ self, inputs, ... }: let
  # Import Niri components
  toKDL = pkgs: lib: import ../../home/yume/niri/_to-KDL.nix { inherit pkgs lib; };
  niriSettings = pkgs: lib: import ../../home/yume/niri/_settings.nix { inherit pkgs lib; };
  niriBinds = pkgs: import ../../home/yume/niri/_binds.nix { inherit pkgs; };
  niriRules = import ../../home/yume/niri/_rules.nix;
in {
  flake.nixosModules.yume = { pkgs, lib, config, ... }: {

    # Polkit agent - required for GUI auth prompts (Shin has this)
    systemd.user.services.polkit-gnome = {
      description = "GNOME PolicyKit Agent";
      wantedBy = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      serviceConfig.ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
    };

    # XDG portals for file pickers, screen share
    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      config.common.default = "*";
    };

    home-manager.users.delta = { pkgs, lib, ... }: {

      # GTK theming (Shin 1:1)
      gtk = {
        enable = true;
        theme = { name = "adw-gtk3-dark"; package = pkgs.adw-gtk3; };
        iconTheme = {
          name = "WhiteSur";
          package = pkgs.whitesur-icon-theme.override {
            boldPanelIcons = true;
            alternativeIcons = true;
          };
        };
        cursorTheme = { name = "Bibata-Original-Ice"; package = pkgs.bibata-cursors; size = 20; };
      };

      # Session env vars (Shin 1:1) - QS_ICON_THEME is critical for noctalia dock icons
      home.sessionVariables = {
        QS_ICON_THEME = "WhiteSur";
        XCURSOR_THEME = "Bibata-Original-Ice";
        XCURSOR_SIZE = "20";
        XDG_ICON_DIR = "${pkgs.whitesur-icon-theme}/share/icons/WhiteSur";
        GSETTINGS_SCHEMA_DIR = "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}/glib-2.0/schemas";
        QT_QPA_PLATFORMTHEME = "qt6ct";
        SDL_VIDEODRIVER = "wayland";
        XDG_SESSION_TYPE = "wayland";
        XDG_CURRENT_DESKTOP = "niri:GNOME";
        XDG_SESSION_DESKTOP = "niri";
        WLR_RENDERER = "vulkan";
        GTK_USE_PORTAL = "1";
        NIXPKGS_ALLOW_UNFREE = "1";
      };

      # GTK bookmarks
      xdg.configFile."gtk-3.0/bookmarks" = {
        force = true;
        text = ''
          file:///home/delta/Downloads Downloads
          file:///home/delta/Documents Documents
          file:///home/delta/Music Music
          file:///home/delta/Pictures Pictures
          file:///home/delta/Videos Videos
        '';
      };

      home.packages = with pkgs; [
        # AI Agents
        inputs.llm-agents.packages.${pkgs.system}.claude-code
        inputs.llm-agents.packages.${pkgs.system}.claude-desktop

        # browser
        google-chrome

        # terminal
        kitty
        foot

        # editor
        neovim

        # file management
        yazi
        kdePackages.dolphin
        file-roller
        xdg-user-dirs

        # wayland/compositor utils
        xwayland-satellite
        wl-clipboard
        cliphist
        libnotify
        xdg-utils

        # noctalia runtime deps (from Shin's quickshell.nix)
        accountsservice
        brightnessctl
        cava
        ddcutil
        elogind
        glib
        gpu-screen-recorder
        material-symbols
        wget
        python3

        # theming
        bibata-cursors
        (whitesur-icon-theme.override {
          boldPanelIcons = true;
          alternativeIcons = true;
        })
        gsettings-desktop-schemas
        adw-gtk3
        kdePackages.qt6ct
        libsForQt5.qt5ct
        kdePackages.breeze

        # color pipeline
        matugen
        awww

        # media
        mpv
        pwvucontrol

        # shell/misc
        atuin
        fastfetch
        grc
        swayimg
        zip
        unzip
        file
        killall
        jq
        pciutils
        imagemagick
        polkit_gnome

      ] ++ (import ../../home/yume/quickshell.nix { inherit pkgs lib inputs self; });

      home.stateVersion = "24.05";

      xdg.configFile."niri/config.kdl".text = builtins.readFile (
        (toKDL pkgs lib).generate "niri-config.kdl" (
          (niriSettings pkgs lib) // { binds = (niriBinds pkgs); } // niriRules
        )
      );
    };
  };
}
