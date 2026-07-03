{ pkgs, lib, config, ... }:
with lib;
let cfg = config.modules.network; in
{
  options.modules.network.enable = mkEnableOption "NetworkManager and iwd";

  config = mkIf cfg.enable {
    finit.services.network-manager = {
      description = "NetworkManager";
      runlevels = "2345";
      conditions = [ "service/syslogd/ready" ];
      command = "${pkgs.networkmanager}/bin/NetworkManager -n";
      notify = "s6";
    };

    finit.services.iwd = {
      description = "iNet Wireless Daemon";
      runlevels = "2345";
      conditions = [ "service/syslogd/ready" ];
      command = "${pkgs.iwd}/bin/iwd";
    };

    environment.etc."NetworkManager/conf.d/wifi-backend.conf".text = ''
      [device]
      wifi.backend=iwd
    '';

    environment.systemPackages = with pkgs; [
      networkmanager
      networkmanager-openvpn
    ];
  };
}
