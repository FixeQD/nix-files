{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nmap
    strace
    jadx
    xxd
    mitmproxy
    ghidra
  ];
}
