{ pkgs, zen-browser, awww, ... }:
{
  home.packages = with pkgs; [
    zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    awww.packages.${pkgs.stdenv.hostPlatform.system}.default
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
    playerctl
    pamixer
    libnotify
    kdePackages.polkit-kde-agent-1
    kdePackages.kdeconnect-kde
    eww
    quickshell
    rofi
    anyrun
  ];
}
