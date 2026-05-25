#!/bin/bash

apply_gaps() {
    local count
    count=$(hyprctl activeworkspace -j | jq '.windows')

    if (( count <= 1 )); then
        hyprctl --batch \
            "keyword general:gaps_in 0;\
             keyword general:gaps_out 0;\
             keyword general:border_size 0" > /dev/null
    else
        hyprctl --batch \
            "keyword general:gaps_in 6;\
             keyword general:gaps_out 12;\
             keyword general:border_size 2" > /dev/null
    fi
}

apply_gaps

handle() {
    case $1 in
        openwindow*|closewindow*|movetoworkspace*|workspace*)
            apply_gaps
            ;;
    esac
}

SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

socat -U - UNIX-CONNECT:"$SOCKET" | while read -r line; do
    handle "$line"
done
