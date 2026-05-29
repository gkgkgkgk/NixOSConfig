#!/usr/bin/env bash
# Hyprland >=0.55 with a Lua config: hyprctl dispatch/keyword take Lua, not
# legacy conf strings. Live config changes go through `hyprctl eval` of an
# hl.* call; dispatchers go through `hyprctl dispatch` with a Lua expression
# that returns a dispatcher object.
hyprctl dispatch 'hl.dsp.workspace.rename({ workspace = 10, name = "⌂" })' >/dev/null
current=$(hyprctl activeworkspace | awk 'NR==1{print $3}')
hyprctl eval 'hl.animation({ leaf = "workspaces", speed = 4, bezier = "default", style = "fade", enabled = true })' >/dev/null
if [ "$current" = "10" ]; then
  hyprctl dispatch 'hl.dsp.focus({ workspace = "previous" })'
else
  hyprctl dispatch 'hl.dsp.focus({ workspace = 10 })'
fi
sleep 0.35
hyprctl eval 'hl.animation({ leaf = "workspaces", speed = 5, bezier = "default", enabled = true })' >/dev/null
