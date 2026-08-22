{ pkgs, ... }:
{
  home.packages = with pkgs; [
    zed-editor
    mitmproxy
    android-tools
    opencode
    opencode-desktop
    lmstudio
    gnumake
    perl
    antigravity-ide
    nvidia-container-toolkit
    fx
    proton-vpn
  ];
}
