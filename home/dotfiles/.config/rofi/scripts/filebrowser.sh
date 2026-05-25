#!/bin/bash

rofi -show filebrowser \
    -display-filebrowser "  Pliki" \
    -theme ~/.config/rofi/theme.rasi \
    -theme-str 'window { width: 700px; } listview { lines: 10; }' \
    -filebrowser-dir "$HOME"
