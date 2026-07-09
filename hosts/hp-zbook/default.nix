{ config, zen-browser, ... }:
{
  imports = [
    ./hardware.nix
    ./boot.nix
    ../../modules/base.nix
    ../../modules/fonts.nix
    ../../modules/locale.nix
    ../../modules/network.nix
    ../../modules/cron.nix
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
  ];

  networking.hostName = "HP-ZBook";

  # Shit...
  services.sysklogd.enable = true;

  modules = {
    audio.enable = true;
    base.enable = true;
    bluetooth.enable = true;
    cron.enable = true;
    desktop.enable = true;
    locale.enable = true;
    mdevd.enable = true;
    network.enable = true;
    performance.enable = true;
    security.enable = true;
    user.enable = true;
    user.name = "fixeq";
    virt.enable = true;
    yggdrasil.enable = true;
    zram.enable = true;
  };

  home-manager.users.${config.modules.user.name} = {
    _module.args = {
      inherit zen-browser;
      username = config.modules.user.name;
    };

    imports = [ ../../home/default.nix ];
  };

  finit.runlevel = 3;
}
