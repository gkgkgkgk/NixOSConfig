#!/usr/bin/env bash
# Redirect non-dashboard windows away from workspace 10 to the next empty workspace.

SOCK="${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"
until [ -S "$SOCK" ]; do sleep 0.3; done

next_empty() {
  local used n=1
  used=$(hyprctl workspaces | awk '/workspace ID/{print $3}')
  while echo "$used" | grep -q "^${n}$"; do
    ((n++))
    [ "$n" -eq 10 ] && ((n++))
  done
  echo "$n"
}

handle() {
  # Quote "openwindow>>" so bash doesn't treat >> as a redirection operator
  case "$1" in
    "openwindow>>"*)
      local data="${1#openwindow>>}"
      local addr="${data%%,*}"
      local rest="${data#*,}"
      local ws="${rest%%,*}"
      local rest2="${rest#*,}"
      local class="${rest2%%,*}"
      if { [ "$ws" = "10" ] || [ "$ws" = "⌂" ]; } && [ "$class" != "com.local.dashboard-term" ]; then
        local target; target=$(next_empty)
        hyprctl dispatch movetoworkspace "${target},address:0x${addr}" >/dev/null 2>&1
      fi
      ;;
  esac
}

nc -U "$SOCK" | while IFS= read -r line; do
  handle "$line"
done
