{ pkgs, lib, config, ... }:
with lib;
let cfg = config.modules.network; in
{
  options.modules.network.enable = mkEnableOption "NetworkManager and iwd";

  config = mkIf cfg.enable {
    services.iwd.enable = true;

    finit.services.network-manager = {
      description = "NetworkManager";
      runlevels = "2345";
      conditions = [ "service/dbus/ready" ];
      command = "${pkgs.networkmanager}/bin/NetworkManager -n";
      notify = "s6";
    };

    services.dbus.packages = [ pkgs.networkmanager pkgs.wpa_supplicant ];

    environment.etc."NetworkManager/conf.d/wifi-backend.conf".text = ''
      [device]
      wifi.backend=iwd
    '';

    environment.etc."NetworkManager/NetworkManager.conf".text = ''
      [main]
      plugins=keyfile

      [keyfile]
      unmanaged-devices=none
    '';

    environment.systemPackages = with pkgs; [
      networkmanager
      networkmanager-openvpn
    ];
  };
}
