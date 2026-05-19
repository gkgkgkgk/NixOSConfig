#!/usr/bin/env bash
source "$HOME/.cache/theme/colors.env"

# Convert #RRGGBB to KDE's decimal "R,G,B" format
rgb() {
  local hex="${1#\#}"
  printf "%d,%d,%d" "0x${hex:0:2}" "0x${hex:2:2}" "0x${hex:4:2}"
}

mkdir -p "$HOME/.config"

cat > "$HOME/.config/kdeglobals" << EOF
[Colors:Button]
BackgroundNormal=$(rgb "$BG")
BackgroundAlternate=$(rgb "$OVERLAY")
ForegroundNormal=$(rgb "$FG")
ForegroundInactive=$(rgb "$OVERLAY")
ForegroundActive=$(rgb "$ACCENT")
ForegroundLink=$(rgb "$ACCENT")
ForegroundVisited=$(rgb "$ACCENT2")
DecorationFocus=$(rgb "$ACCENT")
DecorationHover=$(rgb "$ACCENT2")

[Colors:Selection]
BackgroundNormal=$(rgb "$ACCENT")
BackgroundAlternate=$(rgb "$ACCENT2")
ForegroundNormal=$(rgb "$BG")
ForegroundInactive=$(rgb "$FG")
DecorationFocus=$(rgb "$ACCENT")
DecorationHover=$(rgb "$ACCENT2")

[Colors:Tooltip]
BackgroundNormal=$(rgb "$OVERLAY")
ForegroundNormal=$(rgb "$FG")
DecorationFocus=$(rgb "$ACCENT")
DecorationHover=$(rgb "$ACCENT2")

[Colors:View]
BackgroundNormal=$(rgb "$BG")
BackgroundAlternate=$(rgb "$OVERLAY")
ForegroundNormal=$(rgb "$FG")
ForegroundInactive=$(rgb "$OVERLAY")
ForegroundActive=$(rgb "$ACCENT")
ForegroundLink=$(rgb "$ACCENT")
ForegroundVisited=$(rgb "$ACCENT2")
DecorationFocus=$(rgb "$ACCENT")
DecorationHover=$(rgb "$ACCENT2")

[Colors:Window]
BackgroundNormal=$(rgb "$BG")
BackgroundAlternate=$(rgb "$OVERLAY")
ForegroundNormal=$(rgb "$FG")
ForegroundInactive=$(rgb "$OVERLAY")
ForegroundActive=$(rgb "$ACCENT")
ForegroundLink=$(rgb "$ACCENT")
ForegroundVisited=$(rgb "$ACCENT2")
DecorationFocus=$(rgb "$ACCENT")
DecorationHover=$(rgb "$ACCENT2")

[General]
ColorScheme=WallpaperTheme
Name=WallpaperTheme

[KDE]
contrast=4
EOF

# kdeglobals is read by Sioyek and any other Qt app via qt.platformTheme=kde.
# No process restart needed — Qt apps pick up palette changes on focus events.
