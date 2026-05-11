#!/usr/bin/env bash
# Wallpaper & Theme of the Day
# Themes live in ~/OSConfig/themes/<name>/
#   wallpaper.jpg  — required
#   colors.conf    — optional, defines ACCENT ACCENT2 BG FG OVERLAY

THEMES_DIR="$HOME/OSConfig/themes"

# ── Pick a theme ─────────────────────────────────────────────────────────────
# Pass a theme name as $1 to force a specific one, otherwise rotate daily.
if [[ "$1" == "--random" ]]; then
  mapfile -t THEMES < <(find "$THEMES_DIR" -mindepth 1 -maxdepth 1 -type d | sort)
  [[ ${#THEMES[@]} -eq 0 ]] && { echo "No themes found in $THEMES_DIR"; exit 1; }
  INDEX=$(( RANDOM % ${#THEMES[@]} ))
  THEME="${THEMES[$INDEX]}"
elif [[ -n "$1" ]]; then
  THEME="$THEMES_DIR/$1"
else
  mapfile -t THEMES < <(find "$THEMES_DIR" -mindepth 1 -maxdepth 1 -type d | sort)
  [[ ${#THEMES[@]} -eq 0 ]] && { echo "No themes found in $THEMES_DIR"; exit 1; }
  # Use days-since-epoch so the index advances by 1 each day
  SEED=$(( $(date +%s) / 86400 ))
  INDEX=$(( SEED % ${#THEMES[@]} ))
  THEME="${THEMES[$INDEX]}"
fi

[[ -d "$THEME" ]] || { echo "Theme not found: $THEME"; exit 1; }
echo "Applying theme: $(basename "$THEME")"

# ── Wallpaper ─────────────────────────────────────────────────────────────────
WALLPAPER=$(find "$THEME" -maxdepth 1 \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.webp" \) | head -1)
[[ -z "$WALLPAPER" ]] && { echo "No wallpaper found in $THEME"; exit 1; }

AWWW_SOCKET="/run/user/$(id -u)/wayland-1-awww-daemon.sock"
if ! pgrep -x awww-daemon &>/dev/null; then
  # Remove stale socket left over from a previous session
  rm -f "$AWWW_SOCKET"
  awww-daemon &>/dev/null &
  # Wait until the socket appears (up to 5 seconds)
  for i in $(seq 1 25); do
    [[ -S "$AWWW_SOCKET" ]] && break
    sleep 0.2
  done
fi

awww img "$WALLPAPER" \
  --transition-type simple \
  --transition-duration 0.1

# ── Colors ───────────────────────────────────────────────────────────────────
# Load theme colors if present, otherwise fall back to defaults from colors.nix
if [[ -f "$THEME/colors.conf" ]]; then
  source "$THEME/colors.conf"
else
  ACCENT="#e7d6a7"
  ACCENT2="#908caa"
  BG="#231f36"
  FG="#e0def4"
  OVERLAY="#524535"
fi

hex() { echo "${1#\#}"; }

# Auto-pick clock text color from BG luminance unless colors.conf overrides it
if [[ -z "$CLOCK_TEXT" ]]; then
  local_r=$((16#${BG:1:2}))
  local_g=$((16#${BG:3:2}))
  local_b=$((16#${BG:5:2}))
  local_lum=$(( (299*local_r + 587*local_g + 114*local_b) / 1000 ))
  if (( local_lum < 128 )); then
    CLOCK_TEXT="$FG"
  else
    CLOCK_TEXT="#1a1520"
  fi
fi

hyprctl keyword general:col.active_border \
  "rgba($(hex "$ACCENT")ff) rgba($(hex "$ACCENT2")ff) 45deg"
hyprctl keyword general:col.inactive_border \
  "rgba($(hex "$OVERLAY")aa)"

mkdir -p "$HOME/.config/waybar" "$HOME/.config/rofi"

cat > "$HOME/.config/waybar/theme-colors.css" << EOF
@define-color theme_accent     ${ACCENT};
@define-color theme_accent2    ${ACCENT2};
@define-color theme_bg         ${BG};
@define-color theme_fg         ${FG};
@define-color theme_overlay    ${OVERLAY};
@define-color theme_clock_text ${CLOCK_TEXT};
EOF

cat > "$HOME/.config/rofi/colors.rasi" << EOF
* {
    bg:           ${BG}ed;
    overlay:      ${OVERLAY}d1;
    fg:           ${FG};
    subtle:       ${ACCENT2};
    accent:       ${ACCENT};
    accent2:      ${ACCENT2};
    accent-border: ${ACCENT}2e;
}
EOF

mkdir -p "$HOME/.config/ghostty"
cat > "$HOME/.config/ghostty/theme.ghostty" << EOF
background = ${BG#\#}
foreground = ${FG#\#}
EOF

sleep 2 && pkill -SIGUSR2 waybar 2>/dev/null || true
pkill -SIGUSR2 ghostty 2>/dev/null || true

echo "$(basename "$THEME")" > "$HOME/.cache/current-theme"
