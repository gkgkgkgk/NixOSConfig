#!/usr/bin/env bash
# GTK live-reload hook.
#
# Recolors GTK apps with the wallpaper palette so the file manager (Nemo, GTK3)
# matches Ghostty's background.
#
# Two mechanisms, because Adwaita-dark hardcodes its backgrounds and references
# the legacy @theme_bg_color / @theme_base_color names ZERO times — so on GTK3
# those @define-color overrides are invisible and we must target real CSS nodes
# (.background, .view, headerbar, …) with explicit background-color. GTK4 /
# libadwaita, by contrast, *does* resolve window_bg_color/view_bg_color, so for
# GTK4 the @define-color block is enough.
#
# Files: ~/.config/gtk-3.0/gtk.css (named colors + explicit nodes) and
# ~/.config/gtk-4.0/gtk.css (named colors only). GTK loads these at USER
# priority, above the theme.
#
# Live reload: toggle gsettings gtk-theme between WallpaperTheme-Tick and
# WallpaperTheme-Tock — two symlinks both pointing at Adwaita-dark — so the
# name change forces running apps to re-read CSS without a visual flash.

set -e
source "$HOME/.cache/theme/colors.env"

CACHE_DIR="$HOME/.cache/theme"
mkdir -p "$CACHE_DIR" "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"

# Named colors — honored by libadwaita (GTK4) and any app that reads them.
read -r -d '' NAMED_COLORS << EOF || true
@define-color theme_bg_color $BG;
@define-color theme_base_color $BG;
@define-color theme_fg_color $FG;
@define-color theme_text_color $FG;
@define-color window_bg_color $BG;
@define-color window_fg_color $FG;
@define-color view_bg_color $BG;
@define-color view_fg_color $FG;
@define-color headerbar_bg_color $OVERLAY;
@define-color headerbar_fg_color $FG;
@define-color sidebar_bg_color $OVERLAY;
@define-color sidebar_fg_color $FG;
@define-color popover_bg_color $OVERLAY;
@define-color popover_fg_color $FG;
@define-color card_bg_color $OVERLAY;
@define-color dialog_bg_color $BG;

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

# Explicit node overrides — required for GTK3 (Nemo) where Adwaita hardcodes bg.
read -r -d '' GTK3_NODES << EOF || true
/* Window + content surfaces → Ghostty BG */
.background,
window {
  background-color: $BG;
  color: $FG;
}
.view,
.view text,
textview,
textview text,
treeview.view,
iconview,
scrolledwindow,
viewport,
list,
list row {
  background-color: $BG;
  color: $FG;
}

/* Elevated chrome → OVERLAY */
headerbar,
.titlebar,
toolbar,
.primary-toolbar,
.nemo-places-sidebar,
.sidebar,
placessidebar,
.sidebar list,
popover,
popover.background,
menu,
.menu {
  background-color: $OVERLAY;
  color: $FG;
}

entry {
  background-color: $OVERLAY;
  color: $FG;
}

/* Selection keeps the accent (must come after the bg rules) */
.view:selected,
.view text:selected,
list row:selected,
row:selected,
treeview.view:selected,
iconview:selected {
  background-color: $ACCENT;
  color: $BG;
}
EOF

printf '%s\n\n%s\n' "$NAMED_COLORS" "$GTK3_NODES" > "$HOME/.config/gtk-3.0/gtk.css"
printf '%s\n' "$NAMED_COLORS" > "$HOME/.config/gtk-4.0/gtk.css"

# Tick ↔ Tock toggle. Persist last value so consecutive runs alternate.
STATE="$CACHE_DIR/gtk-toggle"
LAST=$(cat "$STATE" 2>/dev/null || echo Tock)
NEXT=$( [[ "$LAST" == Tick ]] && echo Tock || echo Tick )

gsettings set org.gnome.desktop.interface gtk-theme "WallpaperTheme-$NEXT" 2>/dev/null || true
gsettings set org.gnome.desktop.interface color-scheme prefer-dark 2>/dev/null || true

echo "$NEXT" > "$STATE"
