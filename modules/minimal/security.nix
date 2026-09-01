{ pkgs, lib, config, ... }:
with lib;
let cfg = config.modules.security; in
{
  options.modules.security = {
    enable = mkEnableOption "nftables firewall (default deny inbound)";

    trustedInterfaces = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "tailscale0" ];
      description = "Interfaces whose inbound traffic is fully trusted, bypassing all firewall filtering (e.g. tailscale0 for Tailscale).";
    };
  };

  config = mkIf cfg.enable {
    environment.etc."nftables.conf".text = ''
      flush ruleset

      table inet filter {
        chain input {
          type filter hook input priority 0; policy drop;

          iif "lo" accept
          ${concatMapStringsSep "\n          " (iface: ''iif "${iface}" accept'') cfg.trustedInterfaces}
          ct state established,related accept
          ct state invalid drop

          icmp type echo-request limit rate 5/second accept
          icmpv6 type echo-request limit rate 5/second accept

          # uncomment / extend to open ports, e.g.:
          # tcp dport 22 accept

          limit rate 5/minute log prefix "nft-drop-in: "
        }

        chain forward {
          type filter hook forward priority 0; policy drop;
        }

        chain output {
          type filter hook output priority 0; policy accept;
        }
      }
    '';

    finit.tasks.nftables-setup = {
      description = "Load nftables firewall ruleset";
      runlevels = "S";
      command = "${pkgs.nftables}/bin/nft -f /etc/nftables.conf";
    };

    environment.systemPackages = with pkgs; [ nftables sbctl efibootmgr ];
  };
}
