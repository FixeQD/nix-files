{ config, pkgs, ... }:
{
  imports = [
    ./hardware.nix
    ./boot.nix

    ../../modules/minimal/base.nix
    ../../modules/minimal/locale.nix
    ../../modules/minimal/network.nix
    ../../modules/minimal/cron.nix
    ../../modules/minimal/performance.nix
    ../../modules/minimal/zram.nix
    ../../modules/minimal/security.nix
    ../../modules/minimal/user.nix
    ../../modules/minimal/mdevd.nix
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
    
    network.tailscale.enable = true;
    security.trustedInterfaces = [ "tailscale0" ];

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
