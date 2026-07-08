------------------
---- MONITORS ----
------------------

hl.monitor({
    output   = "eDP-1",
    mode     = "1920x1080@60",
    position = "0x0",
    scale    = 1.00,
})


-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/
hl.on("hyprland.start", function()
    hl.exec_cmd("waybar")
    hl.exec_cmd("awww-daemon --format xrgb")
    hl.exec_cmd("bash ~/.config/awww/randomize.sh 15 random")
    hl.exec_cmd("wl-paste --watch cliphist store")
    hl.exec_cmd("swaync")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("bash ~/.config/eww/scripts/start.sh")
    hl.exec_cmd("dbus-update-activation-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("bash ~/.config/hypr/scripts/nogaps.sh")
    hl.exec_cmd("polkit-kde-authentication-agent-1")
    hl.exec_cmd("pgrep -x kdeconnectd || kdeconnectd")
    hl.exec_cmd("pgrep -x kwalletd6 || kwalletd6")
end)


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("XCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")


-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in  = 6,
        gaps_out = 12,
        border_size = 2,

        col = {
            active_border = {
                colors = {
                    "rgba(cba6f7ff)", "rgba(89b4faff)", "rgba(94e2d5ff)",
                    "rgba(a6e3a1ff)", "rgba(f9e2afff)", "rgba(fab387ff)",
                    "rgba(f38ba8ff)",
                },
                angle = 45,
            },
            inactive_border = "rgba(313244aa)",
        },

        layout = "dwindle",
        resize_on_border = true,
        extend_border_grab_area = 15,
        hover_icon_on_border = true,

        allow_tearing = false,
    },

    decoration = {
        rounding = 10,

        active_opacity     = 1.0,
        inactive_opacity   = 0.94,
        fullscreen_opacity = 1.0,

        shadow = {
            enabled        = true,
            range          = 24,
            render_power   = 3,
            offset         = {0, 3},
            color          = "rgba(1a1a2eee)",
            color_inactive = "rgba(1a1a2e88)",
        },

        dim_inactive = true,
        dim_strength = 0.06,

        blur = {
            enabled            = true,
            size               = 9,
            passes             = 3,
            new_optimizations  = true,
            xray               = false,
            ignore_opacity     = false,
            noise              = 0.0117,
            contrast           = 0.90,
            brightness         = 0.82,
            vibrancy           = 0.22,
            vibrancy_darkness  = 0.0,
            popups             = true,
            popups_ignorealpha = 0.2,
        },
    },

    animations = {
        enabled = true,
    },
})

-- Beziers, see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
hl.curve("smoothOut", { type = "bezier", points = { {0.36, 0},   {0.66, -0.56} } })
hl.curve("smoothIn",  { type = "bezier", points = { {0.25, 1},   {0.5, 1}      } })
hl.curve("overshot",  { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.1}    } })
hl.curve("linear",    { type = "bezier", points = { {0, 0},      {1, 1}        } })
hl.curve("snappy",    { type = "bezier", points = { {0.15, 1},   {0.25, 1}     } })

hl.animation({ leaf = "windows",        enabled = true, speed = 5,  bezier = "overshot", style = "slide" })
hl.animation({ leaf = "windowsOut",     enabled = true, speed = 4,  bezier = "smoothOut", style = "slide" })
hl.animation({ leaf = "windowsMove",    enabled = true, speed = 4,  bezier = "snappy" })                     -- verify
hl.animation({ leaf = "border",         enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "borderangle",    enabled = true, speed = 80, bezier = "linear", style = "loop" })     -- verify
hl.animation({ leaf = "fade",           enabled = true, speed = 7,  bezier = "smoothIn" })
hl.animation({ leaf = "fadeDim",        enabled = true, speed = 7,  bezier = "smoothIn" })                   -- verify
hl.animation({ leaf = "workspaces",     enabled = true, speed = 5,  bezier = "snappy", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 5, bezier = "snappy", style = "slidevert" }) -- verify


----------------------
---- LAYOUTS ----
----------------------

-- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/
hl.config({
    dwindle = {
        preserve_split          = true,
        smart_split             = false,
        smart_resizing          = true,
        force_split             = 0,
        split_width_multiplier  = 1.0,
    },
})

-- See https://wiki.hypr.land/Configuring/Layouts/Master-Layout/
hl.config({
    master = {
        new_status  = "master",
        new_on_top  = true,
        mfact       = 0.55,
        orientation = "left",
    },
})


---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout = "pl",

        numlock_by_default          = true,
        follow_mouse                = 1,
        mouse_refocus               = false,
        float_switch_override_focus = 2,

        touchpad = {
            natural_scroll        = true,
            disable_while_typing  = true,
            tap_to_click          = true,
            drag_lock             = false,
            scroll_factor         = 1.0,
        },

        sensitivity   = 0,
        accel_profile = "flat",
    },
})

hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})


----------------
----  MISC  ----
----------------

hl.config({
    misc = {
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        force_default_wallpaper  = 0,

        mouse_move_enables_dpms  = true,
        key_press_enables_dpms   = true,

        vrr = 0,

        animate_manual_resizes        = true,
        animate_mouse_windowdragging  = true,

        enable_swallow           = true,
        swallow_regex            = "^(kitty|ghostty|Alacritty|foot)$",
        swallow_exception_regex  = "^(wev)$",

        focus_on_activate  = true,
        disable_autoreload = false,
    },

    binds = {
        scroll_event_delay        = 300,
        workspace_back_and_forth  = false,
        allow_workspace_cycles    = true,
        pass_mouse_when_bound     = false,
    },

    xwayland = {
        force_zero_scaling = true,
    },
})


---------------------------------------
---- KEYBINDINGS AND WINDOW RULES ----
---------------------------------------

require("binds")
require("windowrules")
