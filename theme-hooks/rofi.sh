#!/usr/bin/env bash
source "$HOME/.cache/theme/colors.env"
mkdir -p "$HOME/.config/rofi"
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
