#!/bin/bash

cpu_icon=""
ram_icon="🐏"

read_cpu() {
    local -a stat
    read -ra stat < /proc/stat
    echo "${stat[1]} ${stat[3]} ${stat[4]}"
}

a=( $(read_cpu) )
sleep 0.2
b=( $(read_cpu) )

a_active=$(( a[0] + a[1] ))
a_total=$(( a[0] + a[1] + a[2] ))
b_active=$(( b[0] + b[1] ))
b_total=$(( b[0] + b[1] + b[2] ))

delta_active=$(( b_active - a_active ))
delta_total=$(( b_total - a_total ))

if (( delta_total > 0 )); then
    cpu_usage=$(( delta_active * 100 / delta_total ))
else
    cpu_usage=0
fi

ram_usage=$(free -m | awk 'NR==2{ printf "%.0f", $3*100/$2 }')

echo "$cpu_icon ${cpu_usage}%  $ram_icon ${ram_usage}%"
