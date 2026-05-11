#!/usr/bin/env bash
# Wallpaper & Theme of the Day
# Themes live in ~/OSConfig/themes/<name>/
#   wallpaper.jpg  — required
#   colors.conf    — optional, defines ACCENT ACCENT2 BG FG OVERLAY

THEMES_DIR="$HOME/OSConfig/themes"

# ── Pick a theme ──────────────────────────────────────────────────────────────
if [[ "$1" == "--random" ]]; then
  mapfile -t THEMES < <(find "$THEMES_DIR" -mindepth 1 -maxdepth 1 -type d | sort)
  [[ ${#THEMES[@]} -eq 0 ]] && { echo "No themes found in $THEMES_DIR"; exit 1; }
  THEME="${THEMES[$(( RANDOM % ${#THEMES[@]} ))]}"
elif [[ -n "$1" ]]; then
  THEME="$THEMES_DIR/$1"
else
  mapfile -t THEMES < <(find "$THEMES_DIR" -mindepth 1 -maxdepth 1 -type d | sort)
  [[ ${#THEMES[@]} -eq 0 ]] && { echo "No themes found in $THEMES_DIR"; exit 1; }
  THEME="${THEMES[$(( $(date +%s) / 86400 % ${#THEMES[@]} ))]}"
fi

[[ -d "$THEME" ]] || { echo "Theme not found: $THEME"; exit 1; }
echo "Applying theme: $(basename "$THEME")"

# ── Wallpaper ─────────────────────────────────────────────────────────────────
WALLPAPER=$(find "$THEME" -maxdepth 1 \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.webp" \) | head -1)
[[ -z "$WALLPAPER" ]] && { echo "No wallpaper found in $THEME"; exit 1; }

AWWW_SOCKET="/run/user/$(id -u)/wayland-1-awww-daemon.sock"
pkill -x awww-daemon 2>/dev/null; sleep 0.2
rm -f "$AWWW_SOCKET"
awww-daemon &>/dev/null &
for i in $(seq 1 25); do [[ -S "$AWWW_SOCKET" ]] && break; sleep 0.2; done
awww img "$WALLPAPER" --transition-type simple --transition-duration 0.1

# ── Load colors ───────────────────────────────────────────────────────────────
if [[ -f "$THEME/colors.conf" ]]; then
  source "$THEME/colors.conf"
else
  ACCENT="#e7d6a7"
  ACCENT2="#908caa"
  BG="#231f36"
  FG="#e0def4"
  OVERLAY="#524535"
fi

if [[ -z "$CLOCK_TEXT" ]]; then
  r=$((16#${BG:1:2})); g=$((16#${BG:3:2})); b=$((16#${BG:5:2}))
  lum=$(( (299*r + 587*g + 114*b) / 1000 ))
  (( lum < 128 )) && CLOCK_TEXT="$FG" || CLOCK_TEXT="#1a1520"
fi

# ── Canonical colors file — hooks source this ─────────────────────────────────
mkdir -p "$HOME/.cache/theme"
cat > "$HOME/.cache/theme/colors.env" << EOF
export ACCENT="${ACCENT}"
export ACCENT2="${ACCENT2}"
export BG="${BG}"
export FG="${FG}"
export OVERLAY="${OVERLAY}"
export CLOCK_TEXT="${CLOCK_TEXT}"
EOF

echo "$(basename "$THEME")" > "$HOME/.cache/current-theme"

# ── Run all hooks ─────────────────────────────────────────────────────────────
for hook in "$HOME/OSConfig/theme-hooks/"*.sh; do
  [[ -x "$hook" ]] && bash "$hook"
done
