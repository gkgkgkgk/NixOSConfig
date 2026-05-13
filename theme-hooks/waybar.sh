#!/usr/bin/env bash
source "$HOME/.cache/theme/colors.env"
mkdir -p "$HOME/.config/waybar"
cat > "$HOME/.config/waybar/theme-colors.css" << EOF
@define-color theme_accent     ${ACCENT};
@define-color theme_accent2    ${ACCENT2};
@define-color theme_bg         ${BG};
@define-color theme_fg         ${FG};
@define-color theme_overlay    ${OVERLAY};
@define-color theme_clock_text ${FG};
@define-color base01           ${BG};
@define-color base02           ${OVERLAY};
@define-color base05           ${FG};
EOF
pkill -SIGUSR2 waybar 2>/dev/null || true
