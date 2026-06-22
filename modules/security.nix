{ pkgs, lib, config, ... }:
with lib;
let cfg = config.modules.security; in
{
  options.modules.security.enable = mkEnableOption "UFW firewall";

  config = mkIf cfg.enable {
    environment.etc."ufw/ufw.conf".text = ''
      ENABLED=yes
      LOGLEVEL=low
      DEFAULT_INPUT_POLICY=DROP
      DEFAULT_FORWARD_POLICY=DROP
      DEFAULT_OUTPUT_POLICY=ACCEPT
      IPT_SYSCTL=/etc/ufw/sysctl.conf
      IPT_MODULES=
    '';

    finit.services.ufw = {
      description = "UFW firewall";
      runlevels = "2345";
      conditions = [ "service/syslogd/ready" ];
      command = "${pkgs.bash}/bin/bash -c '${pkgs.ufw}/bin/ufw --force reload && sleep infinity'";
    };

    environment.systemPackages = with pkgs; [ ufw sbctl efibootmgr ];
  };
}
