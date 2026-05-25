{ pkgs, zen-browser, anyrun, ... }:
{
  home.packages = with pkgs; [
    anyrun.packages.${pkgs.system}.anyrun
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
