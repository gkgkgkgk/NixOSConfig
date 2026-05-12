#!/usr/bin/env bash
# Kill active window unless it's the permanent home-shell
class=$(hyprctl activewindow 2>/dev/null | awk '/^\s*class:/{print $2; exit}')
[[ -n "$class" && "$class" != "home-shell" ]] && hyprctl dispatch killactive
