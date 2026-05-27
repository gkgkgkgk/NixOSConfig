{ config, pkgs, lib, ... }:
{
  # Append the dashboard-term windowrule to whatever extraConfig already
  # exists in home.nix (mkAfter so it lands after the base block).
  wayland.windowManager.hyprland.extraConfig = lib.mkAfter ''
    # ── Home-workspace dashboard terminal ──────────────────────────────────
    # Managed by ${toString ./supervisor.py}.
    windowrule {
      name = dashboard-term-setup
      match:class = ^com\.local\.dashboard-term$
      workspace = 10 silent
      float = true
      size = 750 480
      move = 20 100%-580
      opacity = 0.88 0.78
    }
  '';

  # Single consolidated supervisor — replaces dashboard-watch.sh,
  # ws-redirect.sh, and dashboard-term-warden.sh.
  wayland.windowManager.hyprland.settings.exec-once = [
    "${pkgs.python3}/bin/python3 ${toString ./supervisor.py}"
  ];

  # The terminal itself: a Ghostty instance with Restart=always so closing
  # it (Ctrl+Shift+Q, $mod+Q, kill) respawns within a second.
  systemd.user.services.dashboard-term = {
    Unit = {
      Description = "Home-workspace embedded terminal widget";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.ghostty}/bin/ghostty --class=com.local.dashboard-term";
      Restart = "always";
      RestartSec = 1;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
