#!/bin/bash

MAX_LEN=28
SCROLL_SPEED=1
STATE_FILE="/tmp/waybar_music_scroll"

if ! command -v playerctl &> /dev/null; then
    echo ""
    exit
fi

player_status=$(playerctl status 2>/dev/null)

if [[ "$player_status" != "Playing" && "$player_status" != "Paused" ]]; then
    rm -f "$STATE_FILE"
    echo ""
    exit
fi

player_name=$(playerctl metadata --format '{{playerName}}' 2>/dev/null)
artist=$(playerctl metadata artist 2>/dev/null)
title=$(playerctl metadata title 2>/dev/null)

case "$player_name" in
    spotify) icon="" ;;
    mpd)     icon="" ;;
    *)       icon="" ;;
esac

[[ "$player_status" == "Paused" ]] && icon=""

full_text="$artist - $title"
text_len=${#full_text}

if (( text_len <= MAX_LEN )); then
    rm -f "$STATE_FILE"
    echo "$icon $full_text"
    exit
fi

pos=0
[[ -f "$STATE_FILE" ]] && pos=$(cat "$STATE_FILE" 2>/dev/null)
[[ -z "$pos" || ! "$pos" =~ ^[0-9]+$ ]] && pos=0

padded="${full_text}   ${full_text}"
chunk="${padded:$pos:$MAX_LEN}"

next_pos=$(( (pos + SCROLL_SPEED) % (text_len + 3) ))
echo "$next_pos" > "$STATE_FILE"

echo "$icon $chunk"
