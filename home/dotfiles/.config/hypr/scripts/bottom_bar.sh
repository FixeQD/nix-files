#!/bin/bash

LOCATION="Warsaw"
SEPARATOR="  |  "

get_weather() {
    weather_data=$(curl -s "https://wttr.in/$LOCATION?format=%c%t")
    echo "$weather_data"
}

get_resources() {
    cpu_icon=""
    ram_icon="🐏"
    cpu_usage=$(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {printf "%.0f", usage}')
    ram_usage=$(free -m | awk 'NR==2{printf "%.0f", $3*100/$2 }')
    echo "$cpu_icon $cpu_usage%  $ram_icon $ram_usage%"
}

get_uptime() {
    uptime_icon="󰅐"
    uptime_str=$(uptime -p | sed -e 's/up //;s/ hours/h/;s/ minutes/m/;s/ hour/h/;s/ minute/m/')
    echo "$uptime_icon $uptime_str"
}

weather_info=$(get_weather)
resources_info=$(get_resources)
uptime_info=$(get_uptime)

echo "$uptime_info$SEPARATOR$resources_info$SEPARATOR$weather_info"
