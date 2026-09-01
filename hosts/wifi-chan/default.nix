{ config, pkgs, ... }:
{
  imports = [
    ./hardware.nix
    ./boot.nix
    ../../modules/base.nix
    ../../modules/locale.nix
    ../../modules/network.nix
    ../../modules/cron.nix
    ../../modules/performance.nix
    ../../modules/zram.nix
    ../../modules/security.nix
    ../../modules/user.nix
    ../../modules/mdevd.nix
  ];

  networking.hostName = "wifi-chan";

  services.sysklogd.enable = true;

  modules = {
    base.enable = true;
    locale.enable = true;
    mdevd.enable = true;

    network.enable = true;
    network.openssh.enable = true;
    network.openssh.permitRootLogin = "no";

    cron.enable = true;
    performance.enable = true;
    security.enable = true;
    zram.enable = true;

    user.enable = true;
    user.name = "fixeq";
  };

  networking.hosts = {
    "127.0.0.1" = [ "localhost" ];
    "127.0.0.2" = [ "wifi-chan" ];
  };

  services.fwupd.enable = true;

  finit.runlevel = 3;
}
