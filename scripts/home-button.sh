#!/usr/bin/env bash
ws=$(hyprctl activeworkspace | awk 'NR==1{print $3}')
if [ "$ws" = "10" ]; then
  printf '{"text":"󰋜","class":"active"}'
else
  printf '{"text":"󰋜"}'
fi
