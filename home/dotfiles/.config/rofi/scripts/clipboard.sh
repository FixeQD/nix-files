#!/bin/bash

cliphist list | rofi -dmenu \
    -p "󰅍  Schowek" \
    -theme ~/.config/rofi/theme.rasi \
    -theme-str 'window { width: 700px; } listview { lines: 10; }' \
    | cliphist decode | wl-copy
