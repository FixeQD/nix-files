{ pkgs, ... }:
{
  home.packages = with pkgs; [
    bun
    typescript-language-server
    eslint
    nodejs
  ];
}
