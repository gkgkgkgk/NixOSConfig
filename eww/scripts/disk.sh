#!/usr/bin/env bash
df -h --output=used,size / | awk 'NR==2{printf "%s/%s", $1, $2}'
