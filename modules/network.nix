{ pkgs, ... }:
{
  finit.services.network-manager = {
    description = "NetworkManager";
    runlevels = "2345";
    conditions = [ "service/syslogd/ready" ];
    command = "${pkgs.networkmanager}/bin/NetworkManager -n";
    notify = "systemd";
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
}
