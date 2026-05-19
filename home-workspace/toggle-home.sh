#!/usr/bin/env bash
hyprctl dispatch renameworkspace 10 ⌂ >/dev/null
current=$(hyprctl activeworkspace | awk 'NR==1{print $3}')
hyprctl keyword animation "workspaces,1,4,default,fade" >/dev/null
if [ "$current" = "10" ]; then
  hyprctl dispatch workspace previous
else
  hyprctl dispatch workspace 10
fi
sleep 0.35
hyprctl keyword animation "workspaces,1,5,default" >/dev/null
