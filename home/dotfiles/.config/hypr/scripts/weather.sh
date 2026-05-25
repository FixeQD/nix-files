#!/bin/bash

LOCATION="Warsaw"

weather_data=$(curl -s "https://wttr.in/$LOCATION?format=%c|%C|%t")

icon=$(echo "$weather_data" | cut -d'|' -f1)
condition=$(echo "$weather_data" | cut -d'|' -f2)
temp=$(echo "$weather_data" | cut -d'|' -f3)

if [[ "$weather_data" == *"render failed"* ]] || [[ -z "$weather_data" ]]; then
    echo "󰖑 brak danych"
    exit 0
fi

echo "$icon $condition $temp"
