#!/usr/bin/env bash
# mpv live-reload hook.
#
# Next-launch colors come from ~/.cache/theme/mpv.conf, which the static
# ~/.config/mpv/mpv.conf (declared in home.nix) `include=`s. Running instances
# get an immediate update via JSON IPC over /tmp/mpvsocket.

set -e
source "$HOME/.cache/theme/colors.env"

CACHE_DIR="$HOME/.cache/theme"
mkdir -p "$CACHE_DIR"

cat > "$CACHE_DIR/mpv.conf" << EOF
osd-color='$FG'
osd-border-color='$BG'
osd-back-color='${OVERLAY}80'
osd-shadow-color='${BG}cc'
EOF

# Push to any running mpv instance via IPC.
SOCK="/tmp/mpvsocket"
if [[ -S "$SOCK" ]]; then
  for prop in osd-color osd-border-color; do
    case "$prop" in
      osd-color)        val="$FG" ;;
      osd-border-color) val="$BG" ;;
    esac
    printf '{ "command": ["set_property", "%s", "%s"] }\n' "$prop" "$val" \
      | socat - "$SOCK" >/dev/null 2>&1 || true
  done
fi
