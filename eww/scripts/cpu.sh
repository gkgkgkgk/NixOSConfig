#!/usr/bin/env bash
# Two-sample measurement for accurate CPU usage
s1=($(awk 'NR==1{print $2,$3,$4,$5,$6,$7,$8}' /proc/stat))
sleep 0.3
s2=($(awk 'NR==1{print $2,$3,$4,$5,$6,$7,$8}' /proc/stat))
t1=0; t2=0
for v in "${s1[@]}"; do ((t1+=v)); done
for v in "${s2[@]}"; do ((t2+=v)); done
idle1=${s1[3]}; idle2=${s2[3]}
total=$((t2-t1)); idle=$((idle2-idle1))
[ "$total" -gt 0 ] && echo $(( (total-idle)*100/total )) || echo 0
