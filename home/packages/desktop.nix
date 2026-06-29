{ pkgs, zen-browser, ... }:
{
  home.packages = with pkgs; [
    zen-browser.packages.${pkgs.system}.default
    waybar
    swaynotificationcenter
    hyprpicker
    hyprshot
    hyprsunset
    hypridle
    hyprlock
    bibata-cursors
    cliphist
    wl-clipboard
    grim
    slurp
    brightnessctl
    playerctl
    pamixer
    libnotify
    polkit-kde-agent
    kdeconnect
    eww
  ];
}
