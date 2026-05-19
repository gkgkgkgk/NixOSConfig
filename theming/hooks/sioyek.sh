#!/usr/bin/env bash
# Sioyek live-reload hook.
#
# Writes colors to prefs_user.config (loaded on top of the bundled prefs.config)
# and uses sioyek's IPC reload_config_file command to refresh running instances.
# Sioyek wants R G B as space-separated 0.0–1.0 floats, not hex.

set -e
source "$HOME/.cache/theme/colors.env"

hex_to_rgb() {
  local h="${1#\#}"
  local r=$((16#${h:0:2}))
  local g=$((16#${h:2:2}))
  local b=$((16#${h:4:2}))
  awk -v r="$r" -v g="$g" -v b="$b" \
    'BEGIN { printf "%.3f %.3f %.3f", r/255, g/255, b/255 }'
}

mkdir -p "$HOME/.config/sioyek"
cat > "$HOME/.config/sioyek/prefs_user.config" << EOF
custom_background_color    $(hex_to_rgb "$BG")
custom_text_color          $(hex_to_rgb "$FG")
dark_mode_background_color $(hex_to_rgb "$BG")
dark_mode_contrast         0.85
text_highlight_color       $(hex_to_rgb "$ACCENT")
link_highlight_color       $(hex_to_rgb "$ACCENT")
search_highlight_color     $(hex_to_rgb "$ACCENT2")
status_bar_color           $(hex_to_rgb "$OVERLAY")
status_bar_text_color      $(hex_to_rgb "$FG")
EOF

# Reload running instances. Gate on pgrep — without this, sioyek treats the
# --execute-command call as a fresh launch and tries to open "reload_config_file"
# as a PDF file path.
if pgrep -x sioyek > /dev/null; then
  sioyek --execute-command reload_config_file 2>/dev/null || true
fi
