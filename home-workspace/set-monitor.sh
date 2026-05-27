#!/usr/bin/env bash
# Apply a Hyprland monitor mode live and persist it across reboots.
#
# Usage: set-monitor.sh <name> <mode>
#   e.g. set-monitor.sh DP-1 2560x1440@143.91
#
# Live change goes through `hyprctl keyword monitor`; persistence is written to
# ~/.config/hypr/monitors.conf, which home.nix sources at the end of its
# Hyprland config (so it overrides the catch-all monitor rule and survives a
# reboot without requiring a nixos/home-manager rebuild).
set -euo pipefail

name="${1:?monitor name required}"
mode="${2:?mode required, e.g. 2560x1440@143.91}"

conf="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/monitors.conf"
line="monitor=${name},${mode},auto,auto"

mkdir -p "$(dirname "$conf")"
touch "$conf"

if grep -q "^monitor=${name}," "$conf"; then
  # Replace the existing rule for this output (| delimiter — monitor names have no |).
  sed -i "s|^monitor=${name},.*|${line}|" "$conf"
else
  echo "$line" >> "$conf"
fi

hyprctl keyword monitor "${name},${mode},auto,auto"
