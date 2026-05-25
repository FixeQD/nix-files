{ pkgs, ... }:
{
  home.packages = with pkgs; [
    uv
    pyright
    python3
  ];
}
