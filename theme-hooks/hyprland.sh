#!/usr/bin/env bash
source "$HOME/.cache/theme/colors.env"
hex() { echo "${1#\#}"; }
hyprctl keyword general:col.active_border \
  "rgba($(hex "$ACCENT")ff) rgba($(hex "$ACCENT2")ff) 45deg"
hyprctl keyword general:col.inactive_border \
  "rgba($(hex "$OVERLAY")aa)"
