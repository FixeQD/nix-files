{ pkgs, lib, config, ... }:
with lib;
let
  cfg = config.modules.yggdrasil;
  homeDir = config.users.users.fixeq.home;
  yggdrasilConfig = builtins.toJSON {
    PrivateKeyPath = "${homeDir}/.config/yggdrasil/yggdrasil.key";
    Peers = [
      "tls://145.239.92.251:51811?key=63190e3dfc084ca063169a607b1786b4829193ebc8623ac0abdfd6608cd8ee6a"
      "quic://145.239.92.251:51812?key=63190e3dfc084ca063169a607b1786b4829193ebc8623ac0abdfd6608cd8ee6a"
      "tcp://145.239.92.251:51813?key=63190e3dfc084ca063169a607b1786b4829193ebc8623ac0abdfd6608cd8ee6a"
    ];
    InterfacePeers = {};
    Listen = [
      "tls://0.0.0.0:0"
      "quic://0.0.0.0:0"
    ];
    MulticastInterfaces = [
      {
        Regex = ".*";
        Beacon = true;
        Listen = true;
        Port = 0;
        Password = "";
      }
    ];
    AllowedPublicKeys = [
      "8f750843e7bc3c4a3868b11b3cb8798b304d430aa3d214c067e8722780d3398a"
    ];
    IfName = "auto";
    IfMTU = 65535;
    NodeInfoPrivacy = false;
    NodeInfo = {};
  };
in
{
  options.modules.yggdrasil.enable = mkEnableOption "Yggdrasil mesh network";

  config = mkIf cfg.enable {
    environment.etc."yggdrasil.conf".text = yggdrasilConfig;

    environment.systemPackages = with pkgs; [
      yggdrasil
      jq
    ];

    finit.services.yggdrasil = {
      description = "Yggdrasil Network";
      runlevels = "2345";
      conditions = [ "service/syslogd/ready" ];
      command = ''
        set -euo pipefail
        umask 0077
        PW=$(${pkgs.coreutils}/bin/cat "${homeDir}/.config/yggdrasil/multicast_password")
        ${pkgs.jq}/bin/jq --arg pw "$PW" '.MulticastInterfaces[0].Password = $pw' \
          /etc/yggdrasil.conf > /run/yggdrasil.conf \
        && exec ${pkgs.yggdrasil}/bin/yggdrasil -useconffile /run/yggdrasil.conf
      '';
    };
  };
}
