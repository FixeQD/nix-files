hl.window_rule({
    name  = "float-dialogs",
    match = { class = "^(file_progress|confirm|dialog|download|notification|error|splash|confirmreset)$" },
    float = true,
})

hl.window_rule({
    name  = "float-dialog-titles",
    match = { title = "^(Open File|branchdialog|Volume Control|Picture-in-Picture|Sharing Indicator)$" },
    float = true,
})

hl.window_rule({
    name  = "float-utility-apps",
    match = { class = "^(Lxappearance|pavucontrol|pavucontrol-qt|viewnior|gucharmap|file-roller|keepassxc)$" },
    float = true,
})

hl.window_rule({
    name  = "float-gnome-settings",
    match = { class = "^(org\\.gnome\\.Settings|gnome-font-viewer)$" },
    float = true,
})

hl.window_rule({
    name  = "float-filemanagers",
    match = { class = "^(dolphin|nemo|thunar|Pcmanfm)$" },
    float = true,
})

hl.window_rule({
    name  = "float-misc",
    match = { class = "^(wdisplays|zathura)$" },
    float = true,
})

hl.window_rule({
    name  = "float-exe",
    match = { class = ".*\\.exe$" },
    float = true,
})

hl.window_rule({
    name  = "rofi",
    match = { class = "^(rofi)$" },

    float        = true,
    stay_focused = true,
    no_anim      = true,
})

hl.window_rule({
    name  = "wlogout-fullscreen",
    match = { class = "^(wlogout)$" },

    fullscreen = true,
    no_anim    = true,
})

hl.window_rule({
    name  = "swaync-opacity",
    match = { title = "^swaync" },
    opacity = "0.0 override 0.0 override",
})
hl.window_rule({ name = "swaync-no-blur",   match = { title = "^swaync" }, no_blur   = true })
hl.window_rule({ name = "swaync-no-shadow", match = { title = "^swaync" }, no_shadow = true })
hl.window_rule({ name = "swaync-no-focus",  match = { title = "^swaync" }, no_focus  = true })

hl.window_rule({
    name  = "volume-control-placement",
    match = { title = "^(Volume Control)$" },

    float = true,
    size  = {800, 600},
    move  = {"75%", "44%"},
})

hl.window_rule({
    name  = "sharing-indicator-corner",
    match = { title = "^(Sharing Indicator)$" },
    move  = {0, 0},
})

hl.window_rule({
    name  = "pip",
    match = { title = "^(Picture-in-Picture)$" },

    float             = true,
    pin               = true,
    keep_aspect_ratio = true,
})

hl.window_rule({
    name  = "jetbrains-splash-no-focus",
    match = { class = "^(jetbrains-.*)$", title = "^(win\\d+)$" },

    no_focus         = true,
    no_initial_focus = true,
})

hl.window_rule({
    name    = "terminal-opacity",
    match   = { class = "^(com.mitchellh.ghostty|kitty|Alacritty|foot)$" },
    opacity = "0.95 override 0.85 override",
})

hl.window_rule({
    name    = "editor-opacity",
    match   = { class = "^(zeditor|Code)$" },
    opacity = "0.90 0.80",
})

hl.window_rule({
    name    = "browser-opacity",
    match   = { class = "^(firefox|zen-Browser)$" },
    opacity = "0.90 0.80",
})

hl.window_rule({
    name      = "browsers-workspace",
    match     = { class = "^(firefox|Zen Browser|chromium)$" },
    workspace = "2",
})

hl.window_rule({
    name      = "editors-workspace",
    match     = { class = "^(Code|code-oss|zeditor)$" },
    workspace = "3",
})

hl.window_rule({
    name      = "chat-workspace",
    match     = { class = "^(discord|WebCord|vesktop)$" },
    workspace = "4",
})

hl.window_rule({
    name      = "music-workspace",
    match     = { class = "^(Spotify|spotify)$" },
    workspace = "5",
})

hl.window_rule({
    name   = "media-viewer",
    match  = { title = "^(Media viewer)$" },

    float  = true,
    size   = {1200, 900},
    center = true,
})

hl.window_rule({
    name      = "steam-immediate",
    match     = { class = "^(steam_app_.*)$" },
    immediate = true,
})

hl.window_rule({
    name      = "minecraft-immediate",
    match     = { class = "^(Minecraft\\*)$" },
    immediate = true,
})

hl.window_rule({
    name  = "vmware",
    match = { class = "^(vmware)$" },

    float        = true,
    immediate    = true,
    stay_focused = true,
})
