-- ================================
-- KEYBINDINGS (migrated from bind.conf)
-- https://wiki.hypr.land/Configuring/Basics/Binds/
-- https://wiki.hypr.land/Configuring/Basics/Dispatchers/
-- ================================

local mainMod = "SUPER"

-- Apps / launchers
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd("ghostty"))
hl.bind("CTRL + ALT + T",       hl.dsp.exec_cmd("ghostty --class floating"))
hl.bind(mainMod .. " + Q",      hl.dsp.window.close())
hl.bind(mainMod .. " + SPACE",  hl.dsp.exec_cmd("anyrun"))
hl.bind(mainMod .. " + F11",    hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mainMod .. " + E",      hl.dsp.exec_cmd("dolphin"))
hl.bind(mainMod .. " + B",      hl.dsp.exec_cmd("zen"))
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd("zen --private-window"))
hl.bind(mainMod .. " + T",      hl.dsp.exec_cmd("Telegram"))
hl.bind(mainMod .. " + C",      hl.dsp.exec_cmd("zeditor"))
hl.bind(mainMod .. " + O",      hl.dsp.exec_cmd("obs"))
hl.bind(mainMod .. " + L",      hl.dsp.exec_cmd("hyprlock"))

-- Window state
hl.bind(mainMod .. " + S", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit")) -- dwindle only

-- Focus movement
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Resize active window
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.resize({ x = 10,  y = 0,   relative = true }))
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.resize({ x = -10, y = 0,   relative = true }))
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.resize({ x = 0,   y = -10, relative = true }))
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.resize({ x = 0,   y = 10,  relative = true }))

-- Mouse move/resize
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Workspaces
for i = 1, 9 do
    hl.bind(mainMod .. " + " .. i,          hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. i,  hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Rofi scripts / launchers
hl.bind(mainMod .. " + X", hl.dsp.exec_cmd("~/.config/rofi/scripts/powermenu.sh"))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("~/.config/rofi/scripts/run.sh"))
hl.bind(mainMod .. " + Z", hl.dsp.exec_cmd("~/.config/rofi/scripts/filebrowser.sh"))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("~/.config/rofi/scripts/clipboard.sh"))
hl.bind(mainMod .. " + SHIFT + SPACE", hl.dsp.exec_cmd("~/.config/rofi/scripts/emoji.sh"))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("~/.config/rofi/scripts/wifi.sh"))

-- Wallpaper (awww)
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("~/.config/awww/picker.sh smooth"))
hl.bind(mainMod .. " + ALT + W",   hl.dsp.exec_cmd("~/.config/awww/randomize.sh 0 random"))

-- Screenshots
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd([[
    FILE=~/Pictures/Screenshots/Screenshot-$(date +%F_%T).png;
    grim -g "$(slurp)" - | tee >(wl-copy) |
    { cat > "$FILE" && [ -s "$FILE" ] &&
    notify-send -i "$FILE" -t 2000 "Screenshot saved" || rm -f "$FILE"; }
]]))

hl.bind("Print", hl.dsp.exec_cmd([[
    FILE=~/Pictures/Screenshots/Screenshot-$(date +%F_%T).png;
    grim - | tee >(wl-copy) > "$FILE" &&
    notify-send -t 2000 "Screenshot saved"
]]))

hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("~/.config/hypr/scripts/reload.sh"))

hl.bind(mainMod .. " + SHIFT + ALT + D", hl.dsp.exec_cmd([[sleep 0.5 && hyprctl dispatch 'hl.dsp.dpms({ action = "disable" })']]))
hl.bind(mainMod .. " + CTRL + D",        hl.dsp.exec_cmd([[hyprctl dispatch 'hl.dsp.dpms({ action = "enable" })']]))

hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("swaync-client -t"))

-- Session
hl.bind(mainMod .. " + SHIFT + ALT + P", hl.dsp.exec_cmd("shutdown -h now"))
hl.bind(mainMod .. " + SHIFT + ALT + R", hl.dsp.exec_cmd("reboot"))
hl.bind(mainMod .. " + SHIFT + ALT + L", hl.dsp.exit())

-- Media keys
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd([[
    pamixer -i 5 &&
    notify-send -h int:value:$(pamixer --get-volume) -t 800 -r 2593
    "Volume $(pamixer --get-volume)%"
]]))

hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd([[
    pamixer -d 5 &&
    notify-send -h int:value:$(pamixer --get-volume) -t 800 -r 2593
    "Volume $(pamixer --get-volume)%"
]]))

hl.bind("XF86AudioMute", hl.dsp.exec_cmd([[
    pamixer -t &&
    notify-send -t 800 -r 2593
    "$(pamixer --get-mute | grep -q true && echo '🔇 Muted' || echo '🔊 Unmuted')"
]]))

hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"))
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"))
hl.bind("XF86AudioStop", hl.dsp.exec_cmd("playerctl stop"))
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })

hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd([[
    brightnessctl set 5%+ &&
    notify-send -h int:value:$(brightnessctl -m | cut -d, -f4 | tr -d %)
    -t 800 -r 2594 "Brightness $(brightnessctl -m | cut -d, -f4)"
]]))

hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd([[
    brightnessctl set 5%- &&
    notify-send -h int:value:$(brightnessctl -m | cut -d, -f4 | tr -d %)
    -t 800 -r 2594 "Brightness $(brightnessctl -m | cut -d, -f4)"
]]))
