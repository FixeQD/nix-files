{ pkgs, ... }:
{
  home.packages = with pkgs; [
    rustup
    rust-analyzer
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
