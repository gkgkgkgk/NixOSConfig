#!/usr/bin/env bash
cat /sys/class/drm/card2/device/gpu_busy_percent 2>/dev/null || echo "0"
