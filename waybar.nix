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
        font-family: 'JetBrainsMono Nerd Font';
        font-size: 12px;
        font-weight: bold;
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
        box-shadow:
          0 0 0 1px alpha(@base05, 0.1),
          0 8px 24px alpha(#000000, 0.3);
        border-radius: 24px;
        padding:       2px 4px;
      }


      /* ── Workspaces carousel ── */
      #workspaces {
        background: transparent;
        padding:    0 2px;
      }

      #workspaces button {
        background:    alpha(@base05, 0.12);
        color:         alpha(@base05, 0.45);
        border-radius: 999px;
        padding:       2px 10px;
        margin:        3px 2px;
        min-width:     0;
      }

      #workspaces button.active {
        background: @base05;
        color:      @base00;
        padding:    2px 20px;
      }

      #workspaces button:hover {
        background: alpha(@base05, 0.25);
        color:      @base05;
      }

      /* ── Clock ── */
      #clock {
        padding:        4px 18px;
        letter-spacing: 0.5px;
        color:          @base05;
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
