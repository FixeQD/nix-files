{ lib, config, ... }:
with lib;
let cfg = config.modules.persistence; in
{
  options.modules.persistence.enable = mkEnableOption "impermanence bind mounts for system state";

  config = mkIf cfg.enable {
    environment.persistence."/persistent" = {
      hideMounts = true;
      directories = [
        "/etc/NetworkManager/system-connections"
        "/etc/ssh"
        "/var/lib/nixos"
        "/var/lib/bluetooth"
        "/var/log"
        "/opt"
      ];
      files = [
        "/etc/machine-id"
      ];
    };
  };
}
