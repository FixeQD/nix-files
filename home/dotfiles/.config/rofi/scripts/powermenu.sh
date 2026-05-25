#!/bin/bash

options=(
    "  Wyłącz"
    "  Uruchom ponownie"
    "  Uśpij"
    "  Zablokuj"
    "  Wyloguj"
    "  Anuluj"
)

chosen=$(printf '%s\n' "${options[@]}" | rofi -dmenu \
    -p "  Zasilanie" \
    -theme ~/.config/rofi/theme.rasi \
    -theme-str '
        window { width: 300px; }
        listview { lines: 6; }
    ' \
    -no-custom \
    -selected-row 3)

case "$chosen" in
    "  Wyłącz")          shutdown -h now ;;
    "  Uruchom ponownie") reboot ;;
    "  Uśpij")            systemctl suspend ;;
    "  Zablokuj")         hyprlock ;;
    "  Wyloguj")          hyprctl dispatch exit ;;
esac
