{ dotfiles, ... }:

let
  common = "${dotfiles}/common";
  pl     = "${dotfiles}/pl";
in
{
  xdg.configFile = {

    # ── Hyprland ──────────────────────────────────────────────────────────────
    "hypr/hyprland.conf"  .source = "${common}/hypr/hyprland.conf";
    "hypr/bind.conf"      .source = "${common}/hypr/bind.conf";
    "hypr/hypridle.conf"  .source = "${common}/hypr/hypridle.conf";
    "hypr/hyprlock.conf"  .source = "${pl}/hypr/hyprlock.conf";

    "hypr/scripts/bottom_bar.sh" = { source = "${common}/hypr/scripts/bottom_bar.sh"; executable = true; };
    "hypr/scripts/music.sh"      = { source = "${common}/hypr/scripts/music.sh";      executable = true; };
    "hypr/scripts/nogaps.sh"     = { source = "${common}/hypr/scripts/nogaps.sh";     executable = true; };
    "hypr/scripts/reload.sh"     = { source = "${common}/hypr/scripts/reload.sh";     executable = true; };
    "hypr/scripts/resources.sh"  = { source = "${common}/hypr/scripts/resources.sh";  executable = true; };
    "hypr/scripts/greeting.sh"   = { source = "${pl}/hypr/scripts/greeting.sh";       executable = true; };
    "hypr/scripts/weather.sh"    = { source = "${pl}/hypr/scripts/weather.sh";        executable = true; };

    # ── Waybar ────────────────────────────────────────────────────────────────
    "waybar/config.jsonc" .source = "${common}/waybar/config.jsonc";
    "waybar/style.css"    .source = "${common}/waybar/style.css";

    # ── Rofi ──────────────────────────────────────────────────────────────────
    "rofi/config.rasi"    .source = "${common}/rofi/config.rasi";
    "rofi/theme.rasi"     .source = "${pl}/rofi/theme.rasi";

    "rofi/scripts/clipboard.sh"  = { source = "${pl}/rofi/scripts/clipboard.sh";  executable = true; };
    "rofi/scripts/emoji.sh"      = { source = "${pl}/rofi/scripts/emoji.sh";      executable = true; };
    "rofi/scripts/filebrowser.sh"= { source = "${pl}/rofi/scripts/filebrowser.sh";executable = true; };
    "rofi/scripts/powermenu.sh"  = { source = "${pl}/rofi/scripts/powermenu.sh";  executable = true; };
    "rofi/scripts/run.sh"        = { source = "${pl}/rofi/scripts/run.sh";        executable = true; };
    "rofi/scripts/wifi.sh"       = { source = "${pl}/rofi/scripts/wifi.sh";       executable = true; };

    # ── Ghostty ───────────────────────────────────────────────────────────────
    "ghostty/config"      .source = "${pl}/ghostty/config";

    # ── swaync ────────────────────────────────────────────────────────────────
    "swaync/style.css"    .source = "${common}/swaync/style.css";
    "swaync/config.json"  .source = "${pl}/swaync/config.json";

    # ── awww (wallpaper daemon) ───────────────────────────────────────────────
    "awww/picker.sh"         = { source = "${pl}/awww/picker.sh";         executable = true; };
    "awww/randomize.sh"      = { source = "${pl}/awww/randomize.sh";      executable = true; };
    "awww/time_wallpaper.sh" = { source = "${pl}/awww/time_wallpaper.sh"; executable = true; };
    "awww/wallpaper.sh"      = { source = "${pl}/awww/wallpaper.sh";      executable = true; };

    # ── eww ───────────────────────────────────────────────────────────────────
    "eww/eww.yuck"        .source = "${common}/eww/eww.yuck";
    "eww/eww.scss"        .source = "${common}/eww/eww.scss";
    "eww/scripts/cpu.sh"       = { source = "${common}/eww/scripts/cpu.sh";       executable = true; };
    "eww/scripts/music.sh"     = { source = "${common}/eww/scripts/music.sh";     executable = true; };
    "eww/scripts/music_art.sh" = { source = "${common}/eww/scripts/music_art.sh"; executable = true; };
    "eww/scripts/start.sh"     = { source = "${common}/eww/scripts/start.sh";     executable = true; };

    # ── fastfetch ─────────────────────────────────────────────────────────────
    "fastfetch/config.jsonc".source = "${pl}/fastfetch/config.jsonc";
  };
}
