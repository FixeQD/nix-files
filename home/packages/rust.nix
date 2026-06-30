{ pkgs, ... }:
{
  home.packages = with pkgs; [
    rustup
    clang
    lldb
    mold
    ccache
    gdb
    cargo-tauri
    cargo-xwin
    cargo-zigbuild
  ];
}
