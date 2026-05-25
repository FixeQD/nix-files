#!/bin/bash

if command -v rofi-emoji &>/dev/null; then
    rofi -show emoji \
        -theme ~/.config/rofi/theme.rasi \
        -theme-str 'window { width: 500px; } listview { lines: 8; }'
    exit
fi

emojis=(
    "😀 Uśmiech" "😂 Śmiech" "🥹 Wzruszenie" "😎 Cool" "🤔 Myślenie"
    "😭 Płacz" "🔥 Ogień" "💀 Czaszka" "👍 OK" "👎 Nie"
    "❤️ Serce" "💜 Fiolet" "⭐ Gwiazda" "✅ Check" "❌ Krzyżyk"
    "🎉 Party" "🚀 Rakieta" "💻 Laptop" "🐧 Pingwin" "🦀 Krab"
    "⚡ Piorun" "🌙 Księżyc" "☀️ Słońce" "🌈 Tęcza" "🎵 Muzyka"
)

chosen=$(printf '%s\n' "${emojis[@]}" | rofi -dmenu \
    -p "  Emoji" \
    -theme ~/.config/rofi/theme.rasi \
    -theme-str 'window { width: 400px; } listview { lines: 8; }')

[[ -z "$chosen" ]] && exit 0

echo "$chosen" | awk '{print $1}' | wl-copy
notify-send "Emoji skopiowane" "$chosen" -t 1500
