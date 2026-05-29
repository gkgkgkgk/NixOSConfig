#!/usr/bin/env bash
# Hyprland >=0.55 with a Lua config: `hyprctl keyword` is rejected ("use
# eval"), so we set the border-color options via `hyprctl eval 'hl.config({...})'`.
# active_border is a gradient (table); inactive_border is a solid color.
source "$HOME/.cache/theme/colors.env"
hex() { echo "${1#\#}"; }
hyprctl eval "hl.config({ general = { col = { active_border = ({ colors = { \"rgba($(hex "$ACCENT")ff)\", \"rgba($(hex "$ACCENT2")ff)\" }, angle = 45 }) } } })"
hyprctl eval "hl.config({ general = { col = { inactive_border = \"rgba($(hex "$OVERLAY")aa)\" } } })"
