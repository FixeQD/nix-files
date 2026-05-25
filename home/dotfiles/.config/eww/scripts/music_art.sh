#!/bin/bash
status=$(playerctl status 2>/dev/null)
[[ "$status" != "Playing" && "$status" != "Paused" ]] && echo "" && exit

art_url=$(playerctl metadata mpris:artUrl 2>/dev/null)
CACHE="/tmp/eww_music_art.jpg"

if [[ "$art_url" == file://* ]]; then
    echo "${art_url#file://}"
elif [[ "$art_url" == http* ]]; then
    curl -sf "$art_url" -o "$CACHE" && echo "$CACHE" || echo ""
else
    echo ""
fi
