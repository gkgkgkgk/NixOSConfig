{ pkgs, ... }:

{
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer        = "top";
        position     = "top";
        height       = 40;
        margin-top   = 8;
        margin-left  = 8;
        margin-right = 8;
        spacing      = 0;
        exclusive    = true;

        modules-left   = [ "hyprland/workspaces" ];
        modules-center = [ "clock" ];
        modules-right  = [];

        "hyprland/workspaces" = {
          format         = "{id}";
          on-click       = "activate";
          on-scroll-up   = "hyprctl dispatch workspace e+1";
          on-scroll-down = "hyprctl dispatch workspace e-1";
        };

        clock = {
          format  = "{:%I:%M %p}";
          tooltip = false;
        };


      };
    };

    style = ''
      @import "/home/gavri/.config/waybar/theme-colors.css";

      * {
        font-family: 'GeistMono Nerd Font', 'JetBrainsMono Nerd Font';
        font-size: 13px;
        font-weight: 500;
        min-height: 0;
        border: none;
        padding: 0;
        margin: 0;
        transition: all 0.15s ease;
      }

      window#waybar {
        background: transparent;
      }

      /* ── Single floating bar ── */
      window#waybar > box {
        border-radius: 24px;
        padding:       2px 4px;
      }

      /* ── Workspaces carousel ── */
      #workspaces {
        background:    alpha(@base02, 0.7);
        border-radius: 999px;
        margin:        3px 2px;
        padding:       0 2px;
      }

      #workspaces button {
        background:    transparent;
        color:         alpha(@base05, 0.4);
        border-radius: 999px;
        padding:       2px 10px;
        margin:        2px;
        min-width:     0;
      }

      #workspaces button.active {
        background: @theme_accent;
        color:      @theme_bg;
        padding:    2px 20px;
      }

      #workspaces button:hover {
        background: alpha(@theme_accent, 0.25);
        color:      @theme_fg;
      }

      /* ── Clock ── */
      #clock {
        padding:        4px 18px;
        font-size:      15px;
        font-weight:    600;
        letter-spacing: 0.5px;
        color:          @theme_clock_text;
        text-shadow:    0 1px 6px rgba(0,0,0,0.9);
      }


      /* ── Tooltips ── */
      tooltip {
        background:    alpha(@base01, 0.95);
        border:        1px solid alpha(@base05, 0.15);
        border-radius: 10px;
        padding:       4px 8px;
        font-size:     11px;
        font-weight:   normal;
      }

      tooltip label {
        color: @base05;
      }
    '';
  };
}
