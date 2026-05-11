#!/usr/bin/env bash
mode="${1:-pct}"
case "$mode" in
  pct)
    awk '/MemTotal/{t=$2}/MemAvailable/{a=$2}END{printf "%d\n",(t-a)*100/t}' /proc/meminfo
    ;;
  gb)
    awk '/MemTotal/{t=$2}/MemAvailable/{a=$2}END{printf "%.1f\n",(t-a)/1048576}' /proc/meminfo
    ;;
  total-gb)
    awk '/MemTotal/{printf "%.0f\n",$2/1048576}' /proc/meminfo
    ;;
esac
