#!/usr/bin/env bash
source "$HOME/.cache/theme/colors.env"
mkdir -p "$HOME/.config/ghostty"
cat > "$HOME/.config/ghostty/theme.ghostty" << EOF
background = ${BG#\#}
foreground = ${FG#\#}
EOF
pkill -SIGUSR2 ghostty 2>/dev/null || true
