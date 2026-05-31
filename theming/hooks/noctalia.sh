#!/usr/bin/env bash
# Write wallpaper colors directly to colors.json.
# Noctalia watches this file with watchChanges:true and hot-reloads automatically.
source "$HOME/.cache/theme/colors.env"

mkdir -p "$HOME/.config/gavbar"

# Single-splash policy: ACCENT is the only neon color. Everything that used to
# be a second accent (mSecondary, mTertiary) or a borrowed accent (mOutline)
# now points at MUTED — a neutral chrome derived from the wallpaper BG/FG.
cat > "$HOME/.config/gavbar/colors.json" << EOF
{
  "mPrimary":          "$ACCENT",
  "mOnPrimary":        "$BG",
  "mSecondary":        "$MUTED",
  "mOnSecondary":      "$FG",
  "mTertiary":         "$MUTED",
  "mOnTertiary":       "$FG",
  "mError":            "#cf6679",
  "mOnError":          "$BG",
  "mSurface":          "$BG",
  "mOnSurface":        "$FG",
  "mSurfaceVariant":   "$OVERLAY",
  "mOnSurfaceVariant": "$FG",
  "mOutline":          "$MUTED",
  "mShadow":           "#000000",
  "mHover":            "$OVERLAY",
  "mOnHover":          "$FG"
}
EOF
