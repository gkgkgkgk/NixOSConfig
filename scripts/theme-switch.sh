#!/usr/bin/env bash
# Wallpaper & Theme of the Day
# Themes live in ~/OSConfig/themes/<name>/
#   wallpaper.jpg  — required
#   colors.conf    — optional, defines ACCENT ACCENT2 BG FG OVERLAY

THEMES_DIR="$HOME/OSConfig/themes"

# ── Pick a theme ─────────────────────────────────────────────────────────────
# Pass a theme name as $1 to force a specific one, otherwise rotate daily.
if [[ -n "$1" ]]; then
  THEME="$THEMES_DIR/$1"
elif [[ "$1" == "--random" ]]; then
  mapfile -t THEMES < <(find "$THEMES_DIR" -mindepth 1 -maxdepth 1 -type d | sort)
  [[ ${#THEMES[@]} -eq 0 ]] && { echo "No themes found in $THEMES_DIR"; exit 1; }
  INDEX=$(( RANDOM % ${#THEMES[@]} ))
  THEME="${THEMES[$INDEX]}"
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

pgrep awww-daemon &>/dev/null || { awww-daemon & sleep 0.5; }

awww img "$WALLPAPER" \
  --transition-type grow \
  --transition-pos center \
  --transition-duration 1.5

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

hyprctl keyword general:col.active_border \
  "rgba($(hex "$ACCENT")ff) rgba($(hex "$ACCENT2")ff) 45deg"
hyprctl keyword general:col.inactive_border \
  "rgba($(hex "$OVERLAY")aa)"

mkdir -p "$HOME/.config/waybar"
cat > "$HOME/.config/waybar/theme-colors.css" << EOF
@define-color theme_accent  ${ACCENT};
@define-color theme_accent2 ${ACCENT2};
@define-color theme_bg      ${BG};
@define-color theme_fg      ${FG};
@define-color theme_overlay ${OVERLAY};
EOF

pkill -SIGUSR2 waybar 2>/dev/null || true

echo "$(basename "$THEME")" > "$HOME/.cache/current-theme"
