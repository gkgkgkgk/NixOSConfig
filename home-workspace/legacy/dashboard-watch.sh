#!/usr/bin/env bash
SOCK="${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"
until [ -S "$SOCK" ]; do sleep 0.3; done
until eww ping >/dev/null 2>&1; do sleep 0.2; done

show_or_hide() {
  if [ "$1" = "10" ]; then
    eww open dashboard 2>/dev/null
  else
    eww close dashboard 2>/dev/null
  fi
}

show_or_hide "$(hyprctl activeworkspace | awk 'NR==1{print $3}')"

nc -U "$SOCK" | while IFS= read -r line; do
  case "$line" in
    "workspacev2>>"*)
      payload="${line#workspacev2>>}"
      show_or_hide "${payload%%,*}"
      ;;
  esac
done
