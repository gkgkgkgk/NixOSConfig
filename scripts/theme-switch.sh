#!/usr/bin/env bash
# Wallpaper & Theme of the Day
# Wallpapers live in ~/Pictures/Background Photos — flat directory of images.

WALLPAPERS_DIR="$HOME/Pictures/Background Photos"
INDEX_FILE="$HOME/.cache/current-theme-index"

# ── Pick a wallpaper ───────────────────────────────────────────────────────────
mapfile -t IMAGES < <(find "$WALLPAPERS_DIR" -maxdepth 1 \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.webp" \) | sort)
[[ ${#IMAGES[@]} -eq 0 ]] && { echo "No wallpapers found in $WALLPAPERS_DIR"; exit 1; }

if [[ "$1" == "--random" ]]; then
  IDX=$(( RANDOM % ${#IMAGES[@]} ))
elif [[ "$1" == "--next" ]]; then
  CURRENT=$(cat "$INDEX_FILE" 2>/dev/null || echo -1)
  IDX=$(( (CURRENT + 1) % ${#IMAGES[@]} ))
elif [[ -n "$1" ]]; then
  WALLPAPER=$(printf '%s\n' "${IMAGES[@]}" | grep -i "/$1" | head -1)
  [[ -z "$WALLPAPER" ]] && { echo "Wallpaper not found: $1"; exit 1; }
  for i in "${!IMAGES[@]}"; do [[ "${IMAGES[$i]}" == "$WALLPAPER" ]] && IDX=$i && break; done
else
  IDX=$(( $(date +%s) / 86400 % ${#IMAGES[@]} ))
fi

[[ -z "$WALLPAPER" ]] && WALLPAPER="${IMAGES[$IDX]}"
echo "${IDX:-0}" > "$INDEX_FILE"

echo "Applying wallpaper: $(basename "$WALLPAPER")"

# ── Set wallpaper immediately ──────────────────────────────────────────────────
awww img "$WALLPAPER" --transition-type wipe --transition-duration 0.5 --transition-fps 144 &

# ── Extract colors (cached per image) ─────────────────────────────────────────
PALETTE_DIR="$HOME/.cache/theme/palettes"
mkdir -p "$PALETTE_DIR"
CACHED="$PALETTE_DIR/$(basename "$WALLPAPER").env"

if [[ -f "$CACHED" ]]; then
  cp "$CACHED" "$HOME/.cache/theme/colors.env"
else
  python3 "$HOME/OSConfig/scripts/generate-colors.py" "$WALLPAPER"
  cp "$HOME/.cache/theme/colors.env" "$CACHED"
fi

# ── Pre-warm next image (colors + page cache) in background ───────────────────
NEXT_IDX=$(( (${IDX:-0} + 1) % ${#IMAGES[@]} ))
NEXT_IMG="${IMAGES[$NEXT_IDX]}"
NEXT_CACHED="$PALETTE_DIR/$(basename "$NEXT_IMG").env"
{ [[ ! -f "$NEXT_CACHED" ]] && python3 "$HOME/OSConfig/scripts/generate-colors.py" \
  "$NEXT_IMG" "$NEXT_CACHED"; cat "$NEXT_IMG" > /dev/null; } &>/dev/null &

echo "$(basename "$WALLPAPER")" > "$HOME/.cache/current-theme"

# ── Run all hooks in parallel ──────────────────────────────────────────────────
for hook in "$HOME/OSConfig/theme-hooks/"*.sh; do
  [[ -x "$hook" ]] && bash "$hook" &
done
wait
