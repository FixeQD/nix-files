{ pkgs, lib, config, ... }:
with lib;
let
  cfg = config.modules.adguardhome;

  workDir = "/var/lib/AdGuardHome";

  settings = recursiveUpdate cfg.settings {
    schema_version = cfg.settings.schema_version or 29;
    http = (cfg.settings.http or { }) // { address = "${cfg.host}:${toString cfg.port}"; };
  };

  adguardStart = pkgs.writeShellScript "adguardhome-start" ''
    set -euo pipefail
    mkdir -p "${workDir}"
    exec ${cfg.package}/bin/AdGuardHome \
      --no-check-update \
      --pidfile /run/AdGuardHome/AdGuardHome.pid \
      --work-dir "${workDir}" \
      --config /etc/AdGuardHome.yaml
  '';
in
{
  imports = [ ../firewall/adguardhome.nix ];

  options.modules.adguardhome = {
    enable = mkEnableOption "AdGuard Home network-wide DNS ad/tracker blocker";

    package = mkOption {
      type = types.package;
      default = pkgs.adguardhome;
      description = "The AdGuard Home package to use.";
    };

    host = mkOption {
      type = types.str;
      default = "0.0.0.0";
      description = "Address the AdGuard Home web UI binds to.";
    };

    port = mkOption {
      type = types.port;
      default = 3000;
      description = "Port the AdGuard Home web UI listens on.";
    };

    settings = mkOption {
      type = types.attrs;
      default = { };
      example = literalExpression ''
        {
          dns.upstream_dns = [ "9.9.9.9#dns.quad9.net" "149.112.112.112#dns.quad9.net" ];
          filtering = {
            protection_enabled = true;
            filtering_enabled = true;
            parental_enabled = false;
          };
        }
      '';
      description = ''
        Declarative AdGuard Home config, written to /etc/AdGuardHome.yaml on activation.
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    environment.etc."AdGuardHome.yaml".text = builtins.toJSON settings;

    finit.services.adguardhome = {
      description = "AdGuard Home DNS server";
      runlevels = "2345";
      conditions = [ "service/syslogd/ready" "service/dhcpcd/ready" ];
      command = "${adguardStart}";
      respawn = true;
      log = true;
    };
  };
}
