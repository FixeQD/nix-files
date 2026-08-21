{ pkgs, zen-browser, ... }:
{
  home.packages = with pkgs; [
    zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    xdg-utils
    bibata-cursors
    cliphist
    wl-clipboard
    playerctl
    pamixer
    libnotify
    kdePackages.polkit-kde-agent-1
    kdePackages.kdeconnect-kde
  ];
}
