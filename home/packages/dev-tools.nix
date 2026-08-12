{ pkgs, ... }:
{
  home.packages = with pkgs; [
    github-cli
    zed-editor
    mitmproxy
    android-tools
    opencode
    lmstudio
    gnumake
    perl
  ];
}
