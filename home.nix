{ config, pkgs, lib, ... }:
let
  colors = import ./colors.nix;
  # Strip leading # so colors can be embedded in rgba() strings
  c = col: builtins.substring 1 6 col;
in
{
  imports = [ ./rofi.nix ./waybar.nix ./eww.nix ];

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
    awww
    socat
    nerd-fonts.geist-mono
  ];

  # ── Hyprland ────────────────────────────────────────────────────────────────
  wayland.windowManager.hyprland = {
    enable = true;
    # Written verbatim — avoids home-manager serialization mangling the rule/matcher format
    extraConfig = ''
      windowrule = float        class:ghostty
      windowrule = size 900 540 class:ghostty
      windowrule = move 64% 4%  class:ghostty

      # ── Workspace 0 dashboard terminal ────────────────────────────────────────
      windowrule = float             class:^(dashboard-term)$
      windowrule = size 500 320      class:^(dashboard-term)$
      windowrule = move 100%-515 10  class:^(dashboard-term)$
      windowrule = opacity 0.88 0.78 class:^(dashboard-term)$
    '';
    settings = {
      monitor = ",preferred,auto,auto";

      "$mod" = "SUPER";

      exec-once = [
        "bash -c '$HOME/OSConfig/scripts/theme-switch.sh && waybar'"
        "mako"
        "nm-applet"
        "bash -c 'eww daemon && $HOME/OSConfig/scripts/dashboard-watch.sh'"
        "[workspace 10 silent] ghostty --class=dashboard-term"
        "$HOME/OSConfig/scripts/ws-redirect.sh"
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
