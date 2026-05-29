#!/usr/bin/env bash
# Apply a Hyprland monitor mode live and persist it across reboots.
#
# Usage: set-monitor.sh <name> <mode>
#   e.g. set-monitor.sh DP-1 2560x1440@143.91
#
# Live change goes through `hyprctl eval 'hl.monitor({...})'` — under a Lua
# config `hyprctl keyword` errors out with "use eval", and `hyprctl monitor`
# expects Lua too.
# Persistence is written to ~/.config/hypr/monitors.lua, which home.nix's
# hyprland.lua loads with dofile() at the end of its config — Hyprland >= 0.55
# uses lua configs, so a hyprlang `monitor=...` line in a sourced file would
# be a parse error.
set -euo pipefail

name="${1:?monitor name required}"
mode="${2:?mode required, e.g. 2560x1440@143.91}"

conf="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/monitors.lua"
# One Lua call per output. Tagged with `--@<name>` so we can find-and-replace
# the line for a given output without parsing the whole file.
line="hl.monitor({ output = \"${name}\", mode = \"${mode}\", position = \"auto\", scale = \"auto\" })  --@${name}"

mkdir -p "$(dirname "$conf")"
if [ ! -s "$conf" ]; then
  printf -- '-- Managed by GavBar Display settings (home-workspace/set-monitor.sh). Edits may be overwritten.\n' > "$conf"
fi

if grep -q -- "--@${name}\$" "$conf"; then
  # Replace the existing rule for this output (| delimiter — output names have no |).
  sed -i "s|^hl\\.monitor.*--@${name}\$|${line}|" "$conf"
else
  printf '%s\n' "$line" >> "$conf"
fi

hyprctl eval "hl.monitor({ output = \"${name}\", mode = \"${mode}\", position = \"auto\", scale = \"auto\" })"
