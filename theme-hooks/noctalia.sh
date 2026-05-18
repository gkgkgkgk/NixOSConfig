#!/usr/bin/env bash
# Write wallpaper colors directly to colors.json.
# Noctalia watches this file with watchChanges:true and hot-reloads automatically.
source "$HOME/.cache/theme/colors.env"

mkdir -p "$HOME/.config/gavbar"

cat > "$HOME/.config/gavbar/colors.json" << EOF
{
  "mPrimary":          "$ACCENT",
  "mOnPrimary":        "$BG",
  "mSecondary":        "$ACCENT2",
  "mOnSecondary":      "$BG",
  "mTertiary":         "$ACCENT2",
  "mOnTertiary":       "$BG",
  "mError":            "#cf6679",
  "mOnError":          "$BG",
  "mSurface":          "$BG",
  "mOnSurface":        "$FG",
  "mSurfaceVariant":   "$OVERLAY",
  "mOnSurfaceVariant": "$FG",
  "mOutline":          "$ACCENT",
  "mShadow":           "#000000",
  "mHover":            "$OVERLAY",
  "mOnHover":          "$FG"
}
EOF
