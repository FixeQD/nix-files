{ config, zen-browser, spicetify-nix, nyth, noctalia, pkgs, nixcord, ... }:
{
  imports = [
    ./hardware.nix
    ./boot.nix
    ../../modules/base.nix
    ../../modules/fonts.nix
    ../../modules/locale.nix
    ../../modules/network.nix
    ../../modules/cron.nix
    ../../modules/cloudflared.nix
    ../../modules/performance.nix
    ../../modules/zram.nix
    ../../modules/audio.nix
    ../../modules/desktop.nix
    ../../modules/security.nix
    ../../modules/secrets.nix
    ../../modules/user.nix
    ../../modules/virt.nix
    ../../modules/bluetooth.nix
    ../../modules/yggdrasil.nix
    ../../modules/mdevd.nix
    ../../modules/nix-ld.nix
    ../../modules/nyth.nix
    ../../modules/ollama.nix
  ];

  networking.hostName = "HP-ZBook";

  # Shit...
  services.sysklogd.enable = true;

  modules = {
    audio.enable = true;
    base.enable = true;
    bluetooth.enable = true;
    cron.enable = true;
    cloudflared.enable = true;
    cloudflared.tokenFile = config.sops.secrets.cloudflared_tunnel_token.path;
    desktop.enable = true;
    locale.enable = true;
    mdevd.enable = true;
    network.enable = true;
    network.tailscale.enable = true;

    network.openssh.enable = true;
    network.openssh.permitRootLogin = "no";

    nix-ld.enable = true;
    nyth.enable = true;

    nix-ld.libraries = with pkgs; [
      stdenv.cc.cc.lib
      icu
      openssl
      gtk3
      zlib
      pango
      harfbuzz
      atk
      cairo
      gdk-pixbuf
      glib
      curl
      libepoxy
      fontconfig

      cudaPackages.cuda_cudart
      nvidia-container-toolkit
    ];

    performance.enable = true;
    security.enable = true;
    user.enable = true;
    user.name = "fixeq";
    virt.enable = true;
    yggdrasil.enable = true;
    zram.enable = true;
    ollama.enable = true;
  };

  networking.hosts = {
    "127.0.0.1" = [ "localhost" ];
    "127.0.0.2" = [ "HP-ZBook" ];
  };

  services.hardware.openrgb = {
    enable = true;
    motherboard = "intel";
  };

  services.fwupd.enable = true;

  home-manager.users.${config.modules.user.name} = {
    _module.args = {
      inherit zen-browser spicetify-nix nyth noctalia;
      username = config.modules.user.name;
    };

    imports = [
      ../../home/default.nix
      spicetify-nix.homeManagerModules.default
      nyth.homeManagerModules.default
      noctalia.homeModules.default
      nixcord.homeModules.nixcord
    ];
  };

  finit.runlevel = 3;
}
