#!/usr/bin/env bash
# Keeps the dashboard-term widget pinned to workspace 10 in its locked
# position and shifts focus away when the cursor leaves its bounds.
#   - 100ms cursor poll: dispatch focuscurrentorlast on mouse-leave
#   - 5s position poll: snap back if it was dragged/resized
#   - socket2 listener: snap back to workspace 10 on movewindowv2
set -u

CLASS="com.local.dashboard-term"
HOME_WS=10
TARGET_W=500
TARGET_H=320
LEFT_X=10            # matches windowrule: move = 10 100%-330
BOTTOM_OFFSET=330    # = TARGET_H + 10 margin from bottom

SOCK="${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"
until [ -S "$SOCK" ]; do sleep 0.3; done

mon_height() {
  hyprctl monitors -j | python3 -c "
import json, sys
for m in json.load(sys.stdin):
    if m.get('focused'):
        print(m['height']); break"
}

# Echoes: ADDR WS X Y W H — or nothing if window not present.
get_geom() {
  hyprctl clients -j | python3 -c "
import json, sys
for c in json.load(sys.stdin):
    if c.get('class') == '$CLASS':
        print(c['address'], c['workspace']['id'],
              c['at'][0], c['at'][1], c['size'][0], c['size'][1])
        break"
}

snap_back() {
  local addr=$1 mh target_y
  mh=$(mon_height)
  target_y=$((mh - BOTTOM_OFFSET))
  hyprctl --batch \
"dispatch movetoworkspacesilent $HOME_WS,address:$addr ; \
dispatch resizewindowpixel exact $TARGET_W $TARGET_H,address:$addr ; \
dispatch movewindowpixel exact $LEFT_X $target_y,address:$addr" >/dev/null 2>&1
}

class_of() {
  hyprctl clients -j | python3 -c "
import json, sys
for c in json.load(sys.stdin):
    if c['address'] == '$1':
        print(c.get('class','')); break"
}

# ── Workspace-lock listener (background) ───────────────────────────────────
{
  nc -U "$SOCK" | while IFS= read -r line; do
    case "$line" in
      "openwindow>>"*)
        # Format: ADDRESS,WORKSPACE_NAME,CLASS,TITLE
        payload="${line#openwindow>>}"
        IFS=',' read -ra parts <<< "$payload"
        if [ "${parts[2]}" = "$CLASS" ]; then
          snap_back "0x${parts[0]}"
        fi
        ;;
      "movewindowv2>>"*)
        payload="${line#movewindowv2>>}"
        IFS=',' read -ra parts <<< "$payload"
        addr="0x${parts[0]}"
        newws="${parts[1]}"
        if [ "$newws" != "$HOME_WS" ] && [ "$(class_of "$addr")" = "$CLASS" ]; then
          snap_back "$addr"
        fi
        ;;
    esac
  done
} &

# ── Main poll: cursor (100ms) + position (5s) ──────────────────────────────
was_inside=0
count=0
while true; do
  geom=$(get_geom)
  if [ -n "$geom" ]; then
    read -r addr ws tx ty tw th <<< "$geom"

    # Position/size snap every ~5s
    if (( count % 50 == 0 )); then
      mh=$(mon_height)
      target_y=$((mh - BOTTOM_OFFSET))
      if (( tx != LEFT_X || ty != target_y || tw != TARGET_W || th != TARGET_H )); then
        snap_back "$addr"
        sleep 0.4
        count=$((count + 4))
        continue
      fi
    fi

    # Cursor-out unfocus
    cursor=$(hyprctl cursorpos)
    cx=${cursor%,*}
    cy=${cursor#*,}
    cy=${cy## }

    if (( cx >= tx && cx < tx + tw && cy >= ty && cy < ty + th )); then
      was_inside=1
    else
      if (( was_inside == 1 )); then
        active=$(hyprctl activewindow -j 2>/dev/null | python3 -c "
import json,sys
try: print(json.load(sys.stdin).get('address',''))
except: pass" 2>/dev/null)
        if [ "$active" = "$addr" ]; then
          # Only shift focus if there's another window on workspace 10 to land
          # on; otherwise leave focus where it is (Hyprland has no real
          # "unfocus" — focuscurrentorlast would drag us to ws 1).
          other=$(hyprctl clients -j | python3 -c "
import json, sys
term='$addr'
for c in json.load(sys.stdin):
    if c['workspace']['id'] == $HOME_WS and c['address'] != term:
        print(c['address']); break")
          if [ -n "$other" ]; then
            hyprctl dispatch focuswindow "address:$other" >/dev/null 2>&1
          fi
        fi
      fi
      was_inside=0
    fi
  fi

  count=$((count + 1))
  sleep 0.1
done
