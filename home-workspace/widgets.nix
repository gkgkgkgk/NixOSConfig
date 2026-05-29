{ config, pkgs, lib, ... }:
{
  # Dashboard-term windowrule and supervisor autostart. Under lua mode the
  # windowrule is a `hl.window_rule({...})` call (added via settings.window_rule),
  # and the supervisor process is registered with its own hl.on("hyprland.start",
  # ...) hook appended to extraConfig — Hyprland accepts multiple callbacks on
  # the same event, so this composes cleanly with home.nix's startup hook.
  wayland.windowManager.hyprland.settings.window_rule = [
    {
      # Managed by ${toString ./supervisor.py}.
      name = "dashboard-term-setup";
      match.class = "^com\\.local\\.dashboard-term$";
      workspace = "10 silent";
      float = true;
      size = [ 750 480 ];
      # 20 100%-580 (monitor-relative) under hyprlang → explicit expression in lua.
      move = [ "20" "monitor_h-580" ];
      opacity = "0.88 0.78";
    }
  ];

  # Single consolidated supervisor — replaces dashboard-watch.sh,
  # ws-redirect.sh, and dashboard-term-warden.sh.
  wayland.windowManager.hyprland.extraConfig = lib.mkAfter ''
    hl.on("hyprland.start", function()
      hl.exec_cmd("${pkgs.python3}/bin/python3 ${toString ./supervisor.py}")
    end)
  '';

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
