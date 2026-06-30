{ pkgs, zen-browser, ... }:
{
  home.packages = with pkgs; [
    zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
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
    kdePackages.polkit-kde-agent-1
    kdePackages.kdeconnect-kde
    eww
  ];
}
