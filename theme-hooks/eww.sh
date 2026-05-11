#!/usr/bin/env bash
source "$HOME/.cache/theme/colors.env"

# Generate eww.scss: prepend live color vars, then append the static styles
rm -f "$HOME/.config/eww/eww.scss"
cat > "$HOME/.config/eww/eww.scss" << EOF
\$bg:      ${BG};
\$overlay: ${OVERLAY};
\$fg:      ${FG};
\$subtle:  ${ACCENT2};
\$accent:  ${ACCENT};
EOF
cat "$HOME/OSConfig/eww/eww-style.scss" >> "$HOME/.config/eww/eww.scss"

eww reload 2>/dev/null || true
