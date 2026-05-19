#!/usr/bin/env bash
# GTK live-reload hook.
#
# Strategy: keep Adwaita-dark's structural colors (window bg, sidebar, text)
# untouched, and only override the *accent* family — selection, focus,
# links — so the wallpaper palette shows up where it matters without
# fighting Adwaita's overall look.
#
# We write directly to ~/.config/gtk-{3,4}.0/gtk.css. GTK3 loads these at
# USER priority, higher than the theme, so @define-color values declared
# here propagate everywhere Adwaita-dark references those named colors.
#
# To force GTK3 to re-read the file on running apps, we toggle gsettings
# between WallpaperTheme-Tick and WallpaperTheme-Tock — two symlinks both
# pointing at Adwaita-dark, so the name change triggers a reload without
# any visual flash.

set -e
source "$HOME/.cache/theme/colors.env"

CACHE_DIR="$HOME/.cache/theme"
mkdir -p "$CACHE_DIR" "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"

read -r -d '' GTK_CSS << EOF || true
/* Accent-only override of Adwaita-dark. Wallpaper-derived ACCENT/ACCENT2
   replace Adwaita's blue selection/focus colors; everything else stays. */
@define-color theme_selected_bg_color $ACCENT;
@define-color theme_selected_fg_color $BG;
@define-color selected_bg_color $ACCENT;
@define-color selected_fg_color $BG;

@define-color accent_color $ACCENT;
@define-color accent_bg_color $ACCENT;
@define-color accent_fg_color $BG;

@define-color link_color $ACCENT;
@define-color visited_link_color $ACCENT2;
EOF

printf '%s\n' "$GTK_CSS" > "$HOME/.config/gtk-3.0/gtk.css"
printf '%s\n' "$GTK_CSS" > "$HOME/.config/gtk-4.0/gtk.css"

# Tick ↔ Tock toggle. Persist last value so consecutive runs alternate.
STATE="$CACHE_DIR/gtk-toggle"
LAST=$(cat "$STATE" 2>/dev/null || echo Tock)
NEXT=$( [[ "$LAST" == Tick ]] && echo Tock || echo Tick )

gsettings set org.gnome.desktop.interface gtk-theme "WallpaperTheme-$NEXT" 2>/dev/null || true
gsettings set org.gnome.desktop.interface color-scheme prefer-dark 2>/dev/null || true

echo "$NEXT" > "$STATE"
