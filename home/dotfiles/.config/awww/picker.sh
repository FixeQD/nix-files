#!/bin/bash

WALLS_DIR="${WALLS_DIR:-$HOME/Obrazy/wallpapers}"
CACHE_DIR="$HOME/.cache/awww/thumbnails"
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
TRANSITION="${1:-smooth}"

mkdir -p "$CACHE_DIR"

mapfile -d '' walls < <(find "$WALLS_DIR" \
    \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) \
    -maxdepth 1 -print0 2>/dev/null | sort -z)

if [[ ${#walls[@]} -eq 0 ]]; then
    notify-send "awww" "Brak tapety w: $WALLS_DIR"
    exit 1
fi

generate_thumb() {
    local src="$1"
    local thumb="$CACHE_DIR/$(echo "$src" | md5sum | cut -d' ' -f1).png"
    [[ -f "$thumb" ]] && echo "$thumb" && return

    if command -v magick &>/dev/null; then
        magick "$src" -resize 200x112^ -gravity center -extent 200x112 "$thumb" 2>/dev/null
    elif command -v convert &>/dev/null; then
        convert "$src" -resize 200x112^ -gravity center -extent 200x112 "$thumb" 2>/dev/null
    fi
    echo "$thumb"
}

has_magick=false
command -v magick &>/dev/null && has_magick=true
command -v convert &>/dev/null && has_magick=true

if $has_magick; then
    entries=()
    for wall in "${walls[@]}"; do
        name=$(basename "$wall")
        thumb="$CACHE_DIR/$(echo "$wall" | md5sum | cut -d' ' -f1).png"
        if [[ -f "$thumb" ]]; then
            entries+=("$name\x00icon\x1f$thumb")
        else
            entries+=("$name")
        fi
    done

    chosen=$(printf '%b\n' "${entries[@]}" | rofi -dmenu \
        -i \
        -p "󰸉  Tapeta" \
        -show-icons \
        -theme-str 'window { width: 800px; } listview { columns: 3; lines: 6; } element { orientation: vertical; } element-icon { size: 100px; }')

    for wall in "${walls[@]}"; do
        thumb="$CACHE_DIR/$(echo "$wall" | md5sum | cut -d' ' -f1).png"
        [[ ! -f "$thumb" ]] && generate_thumb "$wall" &>/dev/null &
    done
else
    chosen=$(printf '%s\n' "${walls[@]}" | xargs -I{} basename {} | \
        rofi -dmenu -i -p "󰸉  Tapeta")
fi

[[ -z "$chosen" ]] && exit 0

for wall in "${walls[@]}"; do
    if [[ "$(basename "$wall")" == "$chosen" ]]; then
        bash "$SCRIPT_DIR/wallpaper.sh" "$wall" "$TRANSITION"
        exit 0
    fi
done
