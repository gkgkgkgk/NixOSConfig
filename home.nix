{ config, pkgs, ... }:

{
  imports = [ ./rofi.nix ];

  home.username = "gavri";
  home.homeDirectory = "/home/gavri";
  home.stateVersion = "25.11";

  gtk.gtk4.theme = config.gtk.theme;

  home.packages = with pkgs; [
    wl-clipboard
    grim
    slurp
    networkmanagerapplet
    wlogout
  ];

  # ── Hyprland ────────────────────────────────────────────────────────────────
  wayland.windowManager.hyprland = {
    enable = true;
    # Written verbatim — avoids home-manager serialization mangling the rule/matcher format
    extraConfig = ''
      windowrule = float class:ghostty
      windowrule = size 900 540 class:ghostty
      windowrule = move 64% 4% class:ghostty
    '';
    settings = {
      monitor = ",preferred,auto,auto";

      "$mod" = "SUPER";

      exec-once = [
        "waybar"
        "mako"
        "nm-applet"
      ];

      general = {
        gaps_in = 5;
        gaps_out = 12;
        border_size = 2;
        layout = "dwindle";
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
        pseudotile = true;
        preserve_split = true;
      };


      # Keybinds
      bind = [
        "$mod, Return, exec, ghostty"
        "$mod, Q, killactive"
        # Use loginctl so SDDM gets a proper session-end signal and restarts its greeter
        "$mod, M, exec, bash -c 'loginctl terminate-session $XDG_SESSION_ID'"
        "$mod, F, togglefloating"
        "$mod, P, pseudo"
        "$mod, J, togglesplit"
        "$mod, Escape, exec, wlogout"
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
        # Move window to workspace
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
      ];

      # Super alone (on release) opens/closes rofi — no Meta+R needed
      bindr = [
        "SUPER, Super_L, exec, pkill rofi || rofi -show drun"
      ];

      # Mouse binds
      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];
    };
  };

  # ── Waybar ──────────────────────────────────────────────────────────────────
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "bottom";
        height = 42;
        spacing = 6;

        modules-left = [ "hyprland/workspaces" "hyprland/window" ];
        modules-center = [ "clock" ];
        modules-right = [ "pulseaudio" "network" "battery" "tray" ];

        "hyprland/workspaces" = {
          format = "{id}";
          on-click = "activate";
        };

        "hyprland/window" = {
          max-length = 50;
        };

        clock = {
          format = "{:%I:%M %p}";
          format-alt = "{:%A, %B %d, %Y}";
          tooltip-format = "<tt>{calendar}</tt>";
        };

        network = {
          format-wifi = "  {essid}";
          format-ethernet = "  wired";
          format-disconnected = "󰤭 ";
          tooltip-format = "{ipaddr}";
        };

        pulseaudio = {
          format = "{icon}  {volume}%";
          format-muted = "󰝟 ";
          format-icons = { default = [ "󰕿" "󰖀" "󰕾" ]; };
          on-click = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        };

        battery = {
          format = "{icon}  {capacity}%";
          format-charging = "󰂄  {capacity}%";
          format-icons = [ "󰂎" "󰁺" "󰁼" "󰁾" "󰂀" "󰂂" "󰁹" ];
          states = { warning = 20; critical = 10; };
        };

        tray = {
          spacing = 8;
        };
      };
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
