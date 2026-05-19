#!/usr/bin/env bash
# imv theme hook.
#
# imv has no live-reload mechanism — colors apply on next launch only.
# Acceptable since image viewing is short-lived.

set -e
source "$HOME/.cache/theme/colors.env"

mkdir -p "$HOME/.config/imv"
cat > "$HOME/.config/imv/config" << EOF
[options]
background = ${BG#\#}
overlay_text_color = ${FG#\#}
overlay_background_color = ${OVERLAY#\#}
EOF
