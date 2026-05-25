{ pkgs, ... }:
{
  home.packages = with pkgs; [
    easyeffects
    helvum
    calf
    lsp-plugins
  ];
}
