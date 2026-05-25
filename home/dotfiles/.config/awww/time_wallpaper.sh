#!/bin/bash

WALLS_DIR="$HOME/Obrazy/wallpapers"
SCRIPT_DIR="$(dirname "$(realpath "$0")")"

MORNING_WALL="$WALLS_DIR/morning"   # 6:00  - 12:00
DAY_WALL="$WALLS_DIR/day"           # 12:00 - 17:00
EVENING_WALL="$WALLS_DIR/evening"   # 17:00 - 21:00
NIGHT_WALL="$WALLS_DIR/night"       # 21:00 - 6:00

TRANSITION="smooth"

get_wall_from_path() {
    local path="$1"

    if [[ -f "$path" ]]; then
        echo "$path"
    elif [[ -d "$path" ]]; then
        local walls=()
        while IFS= read -r -d '' f; do
            walls+=("$f")
        done < <(find "$path" \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) -print0 2>/dev/null)

        if [[ ${#walls[@]} -gt 0 ]]; then
            echo "${walls[$RANDOM % ${#walls[@]}]}"
        else
            echo ""
        fi
    else
        echo ""
    fi
}

hour=$(date +"%H")
hour=${hour#0}  # usuń leading zero

if   (( hour >= 6  && hour < 12 )); then wall_path="$MORNING_WALL"
elif (( hour >= 12 && hour < 17 )); then wall_path="$DAY_WALL"
elif (( hour >= 17 && hour < 21 )); then wall_path="$EVENING_WALL"
else                                      wall_path="$NIGHT_WALL"
fi

wall=$(get_wall_from_path "$wall_path")

if [[ -z "$wall" ]]; then
    echo "Brak tapety dla pory dnia: $wall_path"
    echo "Losuję z głównego folderu..."
    bash "$SCRIPT_DIR/randomize.sh" 0 "$TRANSITION"
else
    bash "$SCRIPT_DIR/wallpaper.sh" "$wall" "$TRANSITION"
fi
