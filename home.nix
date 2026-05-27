{ config, pkgs, lib, ... }:
let
  colors = import ./theming/colors.nix;
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
  imports = [ ./eww ./home-workspace/widgets.nix ];

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
    # Provides the org.cinnamon.desktop.default-applications.terminal gsettings
    # schema that Nemo reads for "Open in Terminal". Note: installing it here is
    # necessary but NOT sufficient — its schema dir must also be on XDG_DATA_DIRS,
    # done via xdg.systemDirs.data below. Without that, Nemo falls back to a
    # hard-coded terminal list (which lacks Ghostty) and fails silently.
    cinnamon-desktop
    # Polkit agent — without one running, GUI mount requests from Nemo/udisks2
    # bounce back as "not authorized" because there's nothing to display the
    # password prompt to.
    hyprpolkitagent
    cifs-utils
    sioyek
    imv
    mpv
    gnome-themes-extra  # provides Adwaita-dark on disk for the Tick/Tock symlinks
    glib                # provides the `gsettings` CLI used by theme-hooks/gtk.sh
  ];

  programs.ghostty.enable = true;

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

  # Interactive bash. shellAliases lands in ~/.bashrc which Ghostty's
  # shell-integration sources even under --posix.
  programs.bash = {
    enable = true;
    shellAliases = {
      # macOS-style: type `open foo.pdf` in any terminal to launch the file
      # in its xdg.mimeApps default app. Backgrounded so the shell isn't held.
      open = "xdg-open";
    };
  };

  dconf.settings = {
    "org/cinnamon/desktop/applications/terminal" = {
      exec = "ghostty";
      exec-arg = "-e";
    };
  };

  # cinnamon-desktop ships its gsettings schema under a non-standard subdir
  # (share/gsettings-schemas/cinnamon-desktop-<ver>/), which home.packages does
  # NOT add to XDG_DATA_DIRS. Without this, glib can't load the schema and Nemo
  # silently falls back to its hard-coded terminal list (which lacks Ghostty).
  xdg.systemDirs.data = [
    "${pkgs.cinnamon-desktop}/share/gsettings-schemas/cinnamon-desktop-${pkgs.cinnamon-desktop.version}"
  ];

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

      # Per-monitor resolution/refresh-rate chosen in GavBar's Display settings
      # is written here by home-workspace/set-monitor.sh. Sourced last so a named
      # rule overrides the catch-all `monitor = ,preferred,auto,auto` above, and
      # it persists across reboots without needing a rebuild.
      source = ~/.config/hypr/monitors.conf
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
        # NOTE: no dbus-update-activation-environment here — home-manager's
        # hyprland systemd integration already imports the environment and starts
        # hyprland-session.target as its own (ordered) exec-once. A second import
        # ran concurrently and raced the session services.
        "awww-daemon"
        # Theme pipeline runs first; noctalia.service waits on its completion via Requires=.
        "bash -c '$HOME/OSConfig/theming/theme-switch.sh'"
        "nm-applet"
        "eww daemon"
        # GavBar (noctalia-shell), the post-startup theme re-apply, and the boot
        # lock are managed as systemd user services — see below.
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
        "$mod SHIFT, W, exec, $HOME/OSConfig/theming/theme-switch.sh --next"
        "$mod SHIFT, S, exec, hyprshot -m region --clipboard-only"
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
        # Home workspace toggle (number-based workspace shortcuts removed on purpose).
        "$mod, D, exec, $HOME/OSConfig/home-workspace/toggle-home.sh"
        # Workspace navigation — routed through GavBar so it follows the same
        # (drag-reorderable) order as the alt-tab switcher. left=prev, right=next.
        "$mod ALT, left,  global, gavbar:wsSwitchPrev"
        "$mod ALT, right, global, gavbar:wsSwitchNext"
        # Move the focused window to the prev/next workspace (same order).
        "$mod CTRL, left,  global, gavbar:wsMovePrev"
        "$mod CTRL, right, global, gavbar:wsMoveNext"
        # GavBar alt-tab workspace switcher: hold Alt, tap Tab to cycle, release Alt to switch
        "ALT, Tab, global, gavbar:altTabNext"
        "ALT SHIFT, Tab, global, gavbar:altTabPrev"
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

  # Hide the original Ghostty entry — only "Terminal" above should appear.
  # The icon must stay set: the alt-tab switcher resolves windows by class
  # (com.mitchellh.ghostty) to THIS entry, so without an icon it falls back to a
  # generic glyph. The launcher is unaffected (it lists the "Terminal" entry).
  xdg.desktopEntries."com.mitchellh.ghostty" = {
    name = "Ghostty";
    exec = "ghostty";
    icon = "com.mitchellh.ghostty";
    noDisplay = true;
  };

  xdg.desktopEntries."file-explorer" = {
    name = "File Explorer";
    exec = "nemo %U";
    icon = "system-file-manager";
    terminal = false;
    categories = [ "System" "FileManager" ];
  };

  # Hide the upstream nemo.desktop (Name=Files) so only "File Explorer" above
  # shows in the launcher. NoDisplay does not affect mime dispatch, so the
  # xdg.mimeApps default (inode/directory = nemo.desktop) keeps working.
  xdg.desktopEntries.nemo = {
    name = "Files";
    exec = "nemo %U";
    noDisplay = true;
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

  # ── Polkit authentication agent ─────────────────────────────────────────────
  # Wakes up alongside the graphical session so GUI privilege prompts (mounting
  # disks in Nemo, password prompts from any pkexec'd tool, etc.) have somewhere
  # to render.
  systemd.user.services.hyprpolkitagent = {
    Unit = {
      Description = "Hyprland Polkit Authentication Agent";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # ── Noctalia/GavBar startup chain ───────────────────────────────────────────
  # Replaces the old `sleep 2 && noctalia-shell; sleep 5 && noctalia.sh; sleep 4 &&
  # noctalia-shell msg lock toggle` chain in Hyprland exec-once. Three units:
  #   1. noctalia-shell.service: the GavBar process, restarted on failure.
  #   2. noctalia-theme-reapply.service: re-applies wallpaper colors after
  #      noctalia's ColorSchemeService overwrites colors.json at startup.
  #   3. noctalia-lock.service: locks the session on boot — with greetd autologin,
  #      this is the de-facto login screen (unlocked with the system password).
  # Small sleeps remain inside the oneshots because noctalia-shell exposes no
  # readiness signal (no sd_notify, no advertised socket path we can probe).
  systemd.user.services.noctalia-shell = {
    Unit = {
      Description = "GavBar / noctalia-shell";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      Environment = "QS_CONFIG_PATH=/home/gavri/Code/GavBar";
      ExecStart = "${pkgs.bash}/bin/bash -lc 'noctalia-shell'";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.services.noctalia-theme-reapply = {
    Unit = {
      Description = "Re-apply wallpaper colors over noctalia's predefined scheme";
      After = [ "graphical-session.target" "noctalia-shell.service" ];
      Requires = [ "noctalia-shell.service" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c 'sleep 3 && ${config.home.homeDirectory}/OSConfig/theming/hooks/noctalia.sh'";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.services.noctalia-lock = {
    Unit = {
      Description = "Lock session on boot (effective login screen)";
      After = [ "graphical-session.target" "noctalia-shell.service" ];
      Requires = [ "noctalia-shell.service" ];
    };
    Service = {
      Type = "oneshot";
      Environment = "QS_CONFIG_PATH=/home/gavri/Code/GavBar";
      # The IPC target is `lockScreen` with function `lock` (idempotent: no-ops if
      # already locked) — the old `lock toggle` hit a non-existent target ("Target
      # not found"). noctalia-shell exposes no readiness signal and `msg` exits 0
      # even on failure, so poll: `msg` prints an error to stdout/stderr when the
      # instance/target isn't ready yet, and prints nothing on success. Retry until
      # the output is empty (= the lock actually fired), capped at ~60s.
      ExecStart = "${pkgs.bash}/bin/bash -lc 'for i in $(seq 1 120); do out=$(noctalia-shell msg lockScreen lock 2>&1); [ -z \"$out\" ] && exit 0; sleep 0.5; done'";
    };
    Install.WantedBy = [ "graphical-session.target" ];
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
