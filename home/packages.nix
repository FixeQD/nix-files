{ pkgs, zen-browser, anyrun, ... }:
{
  home.packages = with pkgs; [
    # ── Wayland / Desktop ────────────────────────────────────────────────────
    anyrun.packages.${pkgs.system}.anyrun
    zen-browser.packages.${pkgs.system}.default
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
    brightnessctl
    playerctl
    pamixer
    libnotify
    polkit-kde-agent
    kdeconnect
    eww

    # ── KDE / Pliki ───────────────────────────────────────────────────────────
    kdePackages.dolphin
    kdePackages.dolphin-plugins
    kdePackages.ffmpegthumbs
    kdePackages.filelight
    kdePackages.kdf
    kdePackages.kdialog
    kdePackages.kio-admin
    kdePackages.kompare
    kdePackages.kwallet
    kdePackages.kwayland-integration

    # ── Media ─────────────────────────────────────────────────────────────────
    mpv
    yt-dlp
    qview
    spotify
    discord

    # ── Audio ─────────────────────────────────────────────────────────────────
    easyeffects
    pavucontrol
    helvum
    calf
    lsp-plugins

    # ── Dev — Rust ────────────────────────────────────────────────────────────
    rustup
    rust-analyzer
    clang
    lldb
    mold
    ccache
    gdb

    # ── Dev — JS / TS ─────────────────────────────────────────────────────────
    bun
    nodePackages.typescript-language-server
    nodePackages.eslint

    # ── Dev — Python ──────────────────────────────────────────────────────────
    uv
    pyright
    python3

    # ── Dev — Cargo extensions ────────────────────────────────────────────────
    cargo-tauri
    cargo-xwin
    cargo-zigbuild

    # ── Dev — Java ────────────────────────────────────────────────────────────
    jdk21

    # ── Dev — Tools ───────────────────────────────────────────────────────────
    github-cli
    zed-editor
    mitmproxy
    android-tools
    opencode

    # ── System ────────────────────────────────────────────────────────────────
    gparted
    ntfs3g
    openrgb
    tailscale
    wireguard-tools
    spicetify-cli
    fwupd

    # ── Sieć ──────────────────────────────────────────────────────────────────
    openssh
    socat

    # ── Archiwa ───────────────────────────────────────────────────────────────
    p7zip
    unrar
    unzip
    zip
  ];
}
