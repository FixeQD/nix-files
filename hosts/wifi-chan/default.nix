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
    ../../modules/minimal/user.nix
    ../../modules/minimal/mdevd.nix
    ../../modules/services/pihole.nix
    ../../modules/firewall/default.nix
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

    cron.enable = true;
    performance.enable = true;
    firewall.enable = true;
    firewall.trustedInterfaces = [ "tailscale0" ];
    zram.enable = true;

    user.enable = true;
    user.name = "fixeq";

    pihole = {
    		enable = true;
      port = 2137;
      settings = {
        dns.upstreams = [
          "9.9.9.9"
          "149.112.112.112"
        ];
      };
    };
  };

  networking.hosts = {
    "127.0.0.1" = [ "localhost" ];
    "127.0.0.2" = [ "wifi-chan" ];
  };

  services.fwupd.enable = true;

  finit.runlevel = 3;
}
