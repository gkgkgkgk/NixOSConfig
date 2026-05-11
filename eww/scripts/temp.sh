#!/usr/bin/env bash
mode="${1:-cpu}"
command -v sensors >/dev/null 2>&1 || { echo "0"; exit; }
case "$mode" in
  cpu)
    sensors 2>/dev/null | awk '
      /Tctl|Tdie|Package id 0|CPU Temperature/ {
        for (i=1; i<=NF; i++) {
          if ($i ~ /^\+[0-9]/) {
            gsub(/[^0-9.]/, "", $i)
            printf "%d\n", $i+0
            exit
          }
        }
      }'
    ;;
  gpu)
    sensors 2>/dev/null | awk '
      /^edge:|^GPU Temperature:|^GPU temp:/ {
        for (i=1; i<=NF; i++) {
          if ($i ~ /^\+[0-9]/) {
            gsub(/[^0-9.]/, "", $i)
            printf "%d\n", $i+0
            exit
          }
        }
      }'
    ;;
esac
