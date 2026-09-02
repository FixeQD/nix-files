{ config, lib, ... }:
with lib;
{
  imports = [ ./default.nix ];

  config = mkIf config.modules.pihole.enable {
    modules.firewall.rules = {
      pihole-dns = {
        proto = "tcp-udp";
        ports = [ 53 ];
        comment = "Pi-hole DNS";
      };

      pihole-web = {
        proto = "tcp";
        ports = [ config.modules.pihole.port ];
        comment = "Pi-hole web UI";
      };
    };
  };
}
