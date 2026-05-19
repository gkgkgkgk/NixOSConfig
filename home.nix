{ config, pkgs, lib, ... }:
let
  colors = import ./colors.nix;
  # Strip leading # so colors can be embedded in rgba() strings
  c = col: builtins.substring 1 6 col;

  # Single source of truth for default GUI apps — drives both desktop entries
  # and xdg.mimeApps. Swap a value here and the whole stack follows.
  myApps = {
    fileManager = "nemo.desktop";
    image       = "imv.desktop";
    pdf         = "sioyek.desktop";
    video       = "mpv.desktop";
  };
in
{
  imports = [ ./waybar.nix ./eww.nix ./home-workspace/widgets.nix ];

  home.username = "gavri";
  home.homeDirectory = "/home/gavri";
  home.stateVersion = "25.11";

  home.pointerCursor = {
    name = "BreezeX-RosePine-Linux";
    package = pkgs.rose-pine-cursor;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  programs.noctalia-shell.enable = true;

  home.packages = with pkgs; [
    wl-clipboard
    grim
    slurp
    networkmanagerapplet
    wlogout
    awww
    socat
    nerd-fonts.geist-mono
    imagemagick
    nemo-with-extensions
    cifs-utils
    sioyek
    imv
    mpv
    gnome-themes-extra  # provides Adwaita-dark on disk for the Tick/Tock symlinks
    glib                # provides the `gsettings` CLI used by theme-hooks/gtk.sh
  ];

  # Two theme directories symlinked to the same Adwaita-dark source.
  # theme-hooks/gtk.sh alternates gsettings between these two names to
  # invalidate GTK3's CSS cache without changing what the user actually sees.
  home.file.".local/share/themes/WallpaperTheme-Tick".source =
    "${pkgs.gnome-themes-extra}/share/themes/Adwaita-dark";
  home.file.".local/share/themes/WallpaperTheme-Tock".source =
    "${pkgs.gnome-themes-extra}/share/themes/Adwaita-dark";

  # NOTE: ~/.config/gtk-3.0/gtk.css and gtk-4.0/gtk.css are owned by
  # theme-hooks/gtk.sh at runtime — not declared here. Home-manager would
  # otherwise create read-only symlinks that the hook can't overwrite.

  # mpv: static config sets the IPC server (used by theme-hooks/mpv.sh to push
  # live theme updates) and pulls in the runtime-written theme file via include=.
  xdg.configFile."mpv/mpv.conf".text = ''
    input-ipc-server=/tmp/mpvsocket
    include=${config.home.homeDirectory}/.cache/theme/mpv.conf
  '';

  qt = {
    enable = true;
    platformTheme.name = "kde";  # Sioyek (and any future Qt app) reads kdeglobals via this
  };

  # ── Hyprland ────────────────────────────────────────────────────────────────
  wayland.windowManager.hyprland = {
    enable = true;
    # Written verbatim — avoids home-manager serialization mangling the rule/matcher format
    extraConfig = ''
      windowrule {
        name = ghostty-setup
        match:class = ghostty
        float = true
        size = 900 540
        move = 64% 4%
      }

      # Dashboard-term windowrule + systemd service live in
      # ./home-workspace/widgets.nix (imported above).
    '';
    settings = {
      monitor = ",preferred,auto,auto";

      "$mod" = "SUPER";

      env = [
        "XCURSOR_THEME,BreezeX-RosePine-Linux"
        "XCURSOR_SIZE,24"
        "NOCTALIA_PAM_SERVICE,noctalia-lock"
        "QT_QPA_PLATFORMTHEME,kde"
      ];

      exec-once = [
        "dbus-update-activation-environment --systemd --all"
        "awww-daemon"
        # Run theme-switch first so Wallpaper.json exists before noctalia-shell scans schemes
        "bash -c '$HOME/OSConfig/scripts/theme-switch.sh'"
        "bash -c 'sleep 2 && QS_CONFIG_PATH=/home/gavri/Code/GavBar noctalia-shell'"
        # Re-run noctalia after GavBar initializes: startup ColorSchemeService overwrites colors.json
        # with the predefined scheme ~2s after launch; this runs after that to apply wallpaper colors.
        "bash -c 'sleep 5 && $HOME/OSConfig/theme-hooks/noctalia.sh'"
        # Lock the session immediately after GavBar is up. With greetd autologin,
        # this is what the user actually sees at boot — the "login screen".
        "bash -c 'sleep 4 && QS_CONFIG_PATH=/home/gavri/Code/GavBar noctalia-shell msg lock toggle'"
        "nm-applet"
        "eww daemon"
      ];

      general = {
        gaps_in = 5;
        gaps_out = 12;
        border_size = 2;
        layout = "dwindle";
        "col.active_border"   = lib.mkForce "rgba(${c colors.accent}ff) rgba(${c colors.subtle}ff) 45deg";
        "col.inactive_border" = lib.mkForce "rgba(${c colors.overlay}aa)";
      };

      decoration = {
        rounding = 10;
        blur = {
          enabled = true;
          size = 6;
          passes = 3;
          new_optimizations = true;
        };
        shadow = {
          enabled = true;
          range = 15;
          render_power = 2;
        };
      };

      animations = {
        enabled = true;
        bezier = "ease, 0.05, 0.9, 0.1, 1.05";
        animation = [
          "windows, 1, 5, ease"
          "windowsOut, 1, 5, default, popin 80%"
          "border, 1, 8, default"
          "fade, 1, 5, default"
          "workspaces, 1, 5, default"
        ];
      };

      input = {
        kb_layout = "us";
        follow_mouse = 1;
        sensitivity = 0;
      };

      dwindle = {
        preserve_split = true;
      };

      workspace = [ "10, defaultName:⌂, persistent:true" ];

      # Keybinds
      bind = [
        "$mod, Return, exec, ghostty"
        "$mod, Q, killactive"
        # Use loginctl so SDDM gets a proper session-end signal and restarts its greeter
        "$mod, M, exec, bash -c 'loginctl terminate-session $XDG_SESSION_ID'"
        "$mod, F, togglefloating"
        "$mod, P, pseudo"
        "$mod, J, layoutmsg, togglesplit"
        "$mod, Escape, exec, wlogout"
        "$mod SHIFT, W, exec, $HOME/OSConfig/scripts/theme-switch.sh --next"
        "$mod SHIFT, S, exec, hyprshot -m region"
        # Volume
        ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86AudioMute,        exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        # Screenshot
        ", Print, exec, grim -g \"$(slurp)\" ~/Pictures/screenshot-$(date +%s).png"
        # Focus
        "$mod, left,  movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up,    movefocus, u"
        "$mod, down,  movefocus, d"
        # Workspaces
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 0, exec, $HOME/OSConfig/scripts/toggle-home.sh"
        "$mod, D, exec, $HOME/OSConfig/scripts/toggle-home.sh"
        # Move window to workspace
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 0, movetoworkspace, 10"
      ];

      # Super alone (on release) toggles GavBar launcher
      bindr = [
        "SUPER, Super_L, exec, QS_CONFIG_PATH=/home/gavri/Code/GavBar noctalia-shell msg launcher toggle"
      ];

      # Mouse binds
      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];
    };
  };

  # ── Desktop entries ─────────────────────────────────────────────────────────
  xdg.desktopEntries.discord = {
    name = "Discord";
    exec = "vesktop %U";
    icon = "vesktop";
    terminal = false;
    categories = [ "Network" "InstantMessaging" ];
  };

  # Hide the vesktop.desktop that ships with the package — only the "Discord" alias above should appear
  xdg.desktopEntries.vesktop = {
    name = "Vesktop";
    exec = "vesktop %U";
    noDisplay = true;
  };

  xdg.desktopEntries.terminal = {
    name = "Terminal";
    exec = "ghostty";
    icon = "com.mitchellh.ghostty";
    terminal = false;
    categories = [ "System" "TerminalEmulator" ];
  };

  # Hide the original Ghostty entry — only "Terminal" above should appear
  xdg.desktopEntries."com.mitchellh.ghostty" = {
    name = "Ghostty";
    exec = "ghostty";
    noDisplay = true;
  };

  xdg.desktopEntries."file-explorer" = {
    name = "File Explorer";
    exec = "nemo %U";
    icon = "system-file-manager";
    terminal = false;
    categories = [ "System" "FileManager" ];
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory"                  = myApps.fileManager;
      "application/x-gnome-saved-search" = myApps.fileManager;

      "application/pdf"                  = myApps.pdf;

      "image/jpeg" = myApps.image;
      "image/png"  = myApps.image;
      "image/gif"  = myApps.image;
      "image/webp" = myApps.image;
      "image/bmp"  = myApps.image;
      "image/tiff" = myApps.image;
      "image/avif" = myApps.image;

      "video/mp4"        = myApps.video;
      "video/x-matroska" = myApps.video;
      "video/webm"       = myApps.video;
      "video/quicktime"  = myApps.video;
    };
  };

  # ── Mako (notifications) ────────────────────────────────────────────────────
  services.mako = {
    enable = true;
    settings = {
      default-timeout = 5000;
      border-radius = 10;
      margin = "10";
      padding = "10,15";
      max-visible = 5;
    };
  };

}
