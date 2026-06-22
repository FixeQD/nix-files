{ pkgs, lib, config, ... }:
with lib;
let cfg = config.modules.bluetooth; in
{
  options.modules.bluetooth.enable = mkEnableOption "Bluetooth daemon";

  config = mkIf cfg.enable {
    hardware.bluetooth = {
      enable      = true;
      powerOnBoot = false;
    };

    finit.services.bluetoothd = {
      description = "Bluetooth daemon";
      runlevels   = "2345";
      conditions  = [ "service/syslogd/ready" ];
      command     = "${pkgs.bluez}/bin/bluetoothd -n";
      notify      = "systemd";
    };

    environment.systemPackages = with pkgs; [
      bluez
      bluez-utils
      blueman
    ];
  };
}
