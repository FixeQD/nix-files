#!/bin/bash

killall waybar
waybar &

killall swaync
swaync &

hyprctl reload

if ! pgrep -x awww-daemon > /dev/null; then
    awww-daemon --format xrgb &
    sleep 0.3
fi

awww img ~/.config/hypr/walls/1.png --transition-type wipe --transition-duration 1.5
