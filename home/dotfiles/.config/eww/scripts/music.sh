#!/bin/bash
status=$(playerctl status 2>/dev/null)
[[ "$status" != "Playing" && "$status" != "Paused" ]] && echo "" && exit
title=$(playerctl metadata title 2>/dev/null)
artist=$(playerctl metadata artist 2>/dev/null)
echo -e "${title}\n${artist}"
