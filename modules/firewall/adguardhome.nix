{ config, lib, ... }:
with lib;
{
  imports = [ ./default.nix ];

  config = mkIf config.modules.adguardhome.enable {
    modules.firewall.rules = {
      adguardhome-dns = {
        proto = "tcp-udp";
        ports = [ 53 ];
        comment = "AdGuard Home DNS";
      };

      adguardhome-web = {
        proto = "tcp";
        ports = [ config.modules.adguardhome.port ];
        comment = "AdGuard Home web UI";
      };
    };
  };
}
