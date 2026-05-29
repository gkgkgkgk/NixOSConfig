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

    # Terminal launcher for Nemo's "Open in Terminal". Nemo launches the
    # configured terminal through GIO, which resolves the bare name `ghostty`
    # to ghostty's running GApplication and routes the request over D-Bus to
    # it — so the new window opens in the *running* instance's directory
    # ($HOME) instead of the folder Nemo set as the spawn cwd. Pointing the
    # terminal at this wrapper (a plain script with no app-id) makes GIO
    # spawn it directly; the child ghostty then honors gtk-single-instance=false
    # and opens a fresh window in the inherited launch directory.
    (writeShellScriptBin "ghostty-here" ''exec ${ghostty}/bin/ghostty "$@"'')
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

  # Nemo reads the terminal from the schema org.cinnamon.desktop.default-applications.terminal,
  # whose dconf *path* is /org/cinnamon/desktop/applications/terminal/ (no "default-").
  # See ghostty-here in home.packages for why this points at a wrapper, not bare ghostty.
  dconf.settings = {
    "org/cinnamon/desktop/applications/terminal" = {
      exec = "ghostty-here";
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
  # Lua-based config (Hyprland >= 0.55). Each `settings.<name>` attribute is
  # rendered by home-manager as `hl.<name>(...)`; list values produce one call
  # per element; `_args` lists generate multi-argument calls; values from
  # `lib.generators.mkLuaInline` are emitted as raw Lua expressions.
  wayland.windowManager.hyprland = let
    lua = lib.generators.mkLuaInline;
    # Bind helpers: build a `bind` list entry with mod-aware key string.
    bindKey  = mod: key: lua ''mod .. " + ${key}"'';
    bareKey  = key: key;
    # exec dispatcher with a literal shell command.
    exec = cmd: lua ''hl.dsp.exec_cmd(${builtins.toJSON cmd})'';
  in {
    enable = true;
    configType = "lua";

    settings = {
      # Local Lua variable: `local mod = "SUPER"`
      mod = { _var = "SUPER"; };

      # Catch-all monitor rule. Per-output overrides are loaded at the bottom
      # of the file via the dofile() in extraConfig (home-workspace/set-monitor.sh
      # writes ~/.config/hypr/monitors.lua).
      monitor = {
        output = "";
        mode = "preferred";
        position = "auto";
        scale = "auto";
      };

      # General settings, decoration, input, dwindle — one consolidated
      # hl.config({...}) call.
      config = {
        general = {
          gaps_in = 5;
          gaps_out = 12;
          border_size = 2;
          layout = "dwindle";
          col = {
            active_border = lib.mkForce (lua ''{ colors = { "rgba(${c colors.accent}ff)", "rgba(${c colors.subtle}ff)" }, angle = 45 }'');
            inactive_border = lib.mkForce "rgba(${c colors.overlay}aa)";
          };
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

        animations.enabled = true;

        input = {
          kb_layout = "us";
          follow_mouse = 1;
          sensitivity = 0;
        };

        dwindle.preserve_split = true;
      };

      # Bezier curves used by the animations below. `default` is built-in so
      # we only need to register our custom `ease`.
      curve = {
        _args = [
          "ease"
          { type = "bezier"; points = [ [ 0.05 0.9 ] [ 0.1 1.05 ] ]; }
        ];
      };

      # Individual animation tree entries. `enabled = true` is in config.animations above.
      animation = [
        { leaf = "windows";     enabled = true; speed = 5; bezier = "ease"; }
        { leaf = "windowsOut";  enabled = true; speed = 5; bezier = "default"; style = "popin 80%"; }
        { leaf = "border";      enabled = true; speed = 8; bezier = "default"; }
        { leaf = "fade";        enabled = true; speed = 5; bezier = "default"; }
        { leaf = "workspaces";  enabled = true; speed = 5; bezier = "default"; }
      ];

      # Persistent workspace (was hyprlang `workspace = 10, defaultName:⌂, persistent:true`).
      workspace_rule = {
        workspace = "10";
        default_name = "⌂";
        persistent = true;
      };

      # Environment variables — each `_args = [ K V ]` produces hl.env(K, V).
      env = [
        { _args = [ "XCURSOR_THEME"        "BreezeX-RosePine-Linux" ]; }
        { _args = [ "XCURSOR_SIZE"         "24" ]; }
        { _args = [ "NOCTALIA_PAM_SERVICE" "noctalia-lock" ]; }
        { _args = [ "QT_QPA_PLATFORMTHEME" "kde" ]; }
      ];

      # Window rules. The first two were previously written as verbatim
      # hyprlang in extraConfig.
      window_rule = [
        {
          name = "ghostty-setup";
          match.class = "ghostty";
          float = true;
          size = [ 900 540 ];
          # 64% 4% (monitor-relative) under hyprlang → explicit expressions in lua.
          move = [ "monitor_w*0.64" "monitor_h*0.04" ];
        }
        # Nemo: translucent window (frosted with the bar's blur behind it) so the
        # file explorer matches Ghostty's transparency. Color comes from the GTK
        # hook (theming/hooks/gtk.sh) which sets the background to the wallpaper BG.
        {
          name = "nemo-opacity";
          match.class = "[Nn]emo";
          opacity = "0.85";
        }
        # Dashboard-term windowrule lives in ./home-workspace/widgets.nix (imported above).
      ];

      # Keybinds. Each entry is `hl.bind(keys, dispatcher[, flags])`.
      bind = [
        # Apps / window mgmt
        { _args = [ (bindKey "mod" "Return")     (exec "ghostty") ]; }
        { _args = [ (bindKey "mod" "Q")          (lua ''hl.dsp.window.close()'') ]; }
        # Use loginctl so SDDM gets a proper session-end signal and restarts its greeter.
        { _args = [ (bindKey "mod" "M")          (exec "bash -c 'loginctl terminate-session $XDG_SESSION_ID'") ]; }
        { _args = [ (bindKey "mod" "F")          (lua ''hl.dsp.window.float({ action = "toggle" })'') ]; }
        { _args = [ (bindKey "mod" "P")          (lua ''hl.dsp.window.pseudo()'') ]; }
        { _args = [ (bindKey "mod" "J")          (lua ''hl.dsp.layout("togglesplit")'') ]; }
        { _args = [ (bindKey "mod" "Escape")     (exec "wlogout") ]; }
        { _args = [ (bindKey "mod" "SHIFT + W")  (exec "$HOME/OSConfig/theming/theme-switch.sh --next") ]; }
        { _args = [ (bindKey "mod" "SHIFT + S")  (exec "hyprshot -m region --clipboard-only") ]; }

        # Volume
        { _args = [ (bareKey "XF86AudioRaiseVolume") (exec "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+") ]; }
        { _args = [ (bareKey "XF86AudioLowerVolume") (exec "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-") ]; }
        { _args = [ (bareKey "XF86AudioMute")        (exec "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle") ]; }

        # Screenshot
        { _args = [ (bareKey "Print") (exec ''grim -g "$(slurp)" ~/Pictures/screenshot-$(date +%s).png'') ]; }

        # Focus
        { _args = [ (bindKey "mod" "left")  (lua ''hl.dsp.focus({ direction = "left"  })'') ]; }
        { _args = [ (bindKey "mod" "right") (lua ''hl.dsp.focus({ direction = "right" })'') ]; }
        { _args = [ (bindKey "mod" "up")    (lua ''hl.dsp.focus({ direction = "up"    })'') ]; }
        { _args = [ (bindKey "mod" "down")  (lua ''hl.dsp.focus({ direction = "down"  })'') ]; }

        # Home workspace toggle (number-based workspace shortcuts removed on purpose).
        { _args = [ (bindKey "mod" "D") (exec "$HOME/OSConfig/home-workspace/toggle-home.sh") ]; }

        # Workspace navigation — routed through GavBar so it follows the same
        # (drag-reorderable) order as the alt-tab switcher. left=prev, right=next.
        { _args = [ (bindKey "mod" "ALT + left")   (lua ''hl.dsp.global("gavbar:wsSwitchPrev")'') ]; }
        { _args = [ (bindKey "mod" "ALT + right")  (lua ''hl.dsp.global("gavbar:wsSwitchNext")'') ]; }
        # Move the focused window to the prev/next workspace (same order).
        { _args = [ (bindKey "mod" "CTRL + left")  (lua ''hl.dsp.global("gavbar:wsMovePrev")'') ]; }
        { _args = [ (bindKey "mod" "CTRL + right") (lua ''hl.dsp.global("gavbar:wsMoveNext")'') ]; }
        # GavBar alt-tab workspace switcher: hold Alt, tap Tab to cycle, release Alt to switch.
        { _args = [ "ALT + Tab"         (lua ''hl.dsp.global("gavbar:altTabNext")'') ]; }
        { _args = [ "ALT + SHIFT + Tab" (lua ''hl.dsp.global("gavbar:altTabPrev")'') ]; }

        # Super alone (on release) toggles GavBar launcher. Replaces the old
        # `bindr = SUPER, Super_L, ...`; the lua port uses { release = true }.
        { _args = [
            "SUPER + SUPER_L"
            (exec "QS_CONFIG_PATH=/home/gavri/Code/GavBar noctalia-shell msg launcher toggle")
            { release = true; }
          ];
        }

        # Mouse binds (movewindow/resizewindow → window.drag/window.resize).
        { _args = [ (bindKey "mod" "mouse:272") (lua ''hl.dsp.window.drag()'')   { mouse = true; } ]; }
        { _args = [ (bindKey "mod" "mouse:273") (lua ''hl.dsp.window.resize()'') { mouse = true; } ]; }
      ];
    };

    # Autostart and per-output monitor overrides. Both files contribute their
    # own hl.on("hyprland.start", ...) via lib.mkAfter, which Hyprland handles
    # as separate callbacks on the same event.
    extraConfig = ''
      hl.on("hyprland.start", function()
        -- NOTE: no dbus-update-activation-environment here — home-manager's
        -- hyprland systemd integration already imports the environment and
        -- starts hyprland-session.target as its own startup hook. A second
        -- import ran concurrently and raced the session services.
        hl.exec_cmd("awww-daemon")
        -- Theme pipeline runs first; noctalia.service waits on its completion via Requires=.
        hl.exec_cmd("bash -c '$HOME/OSConfig/theming/theme-switch.sh'")
        hl.exec_cmd("nm-applet")
        hl.exec_cmd("eww daemon")
        -- GavBar (noctalia-shell), the post-startup theme re-apply, and the
        -- boot lock are managed as systemd user services — see below.
      end)

      -- Per-monitor mode chosen in GavBar's Display settings is written to
      -- ~/.config/hypr/monitors.lua by home-workspace/set-monitor.sh. Loaded
      -- here so any hl.monitor({output="DP-2", ...}) call inside overrides
      -- the catch-all rule above; lives outside the nix store so it persists
      -- across reboots without a rebuild.
      do
        local f = io.open(os.getenv("HOME") .. "/.config/hypr/monitors.lua", "r")
        if f then
          f:close()
          dofile(os.getenv("HOME") .. "/.config/hypr/monitors.lua")
        end
      end
    '';
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
  # noctalia-shell msg lock toggle` chain in Hyprland exec-once. Two units:
  #   1. noctalia-shell.service: the GavBar process, restarted on failure.
  #   2. noctalia-lock.service: locks the session on boot — with greetd autologin,
  #      this is the de-facto login screen (unlocked with the system password).
  # Small sleeps remain inside the lock oneshot because noctalia-shell exposes no
  # readiness signal (no sd_notify, no advertised socket path we can probe).
  #
  # Color theming: colors.json is owned solely by the theming pipeline
  # (theming/hooks/noctalia.sh, run by theme-switch.sh). NOCTALIA_EXTERNAL_COLORS=1
  # tells GavBar's ColorSchemeService to never write colors.json, so it no longer
  # clobbers our wallpaper colors with its predefined scheme at startup. This
  # retired the old noctalia-theme-reapply.service, which existed only to re-stamp
  # our colors 3s after that clobber.
  systemd.user.services.noctalia-shell = {
    Unit = {
      Description = "GavBar / noctalia-shell";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      Environment = [
        "QS_CONFIG_PATH=/home/gavri/Code/GavBar"
        "NOCTALIA_EXTERNAL_COLORS=1"
      ];
      ExecStart = "${pkgs.bash}/bin/bash -lc 'noctalia-shell'";
      Restart = "on-failure";
      RestartSec = 2;
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

  # NOTE: no notification daemon here. GavBar/noctalia owns
  # org.freedesktop.Notifications on the bus, so a second daemon (mako) never
  # binds it — it sat disabled/inactive. Notification behavior is configured in
  # GavBar's settings.json (`notifications` key).

}
