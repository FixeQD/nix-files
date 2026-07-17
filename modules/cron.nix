{ pkgs, lib, config, ... }:
with lib;
let cfg = config.modules.cron; in
{
  options.modules.cron.enable = mkEnableOption "Cron daemon with periodic tasks";

  config = mkIf cfg.enable {
    finit.services.cronie = {
      description = "Cron daemon";
      runlevels = "2345";
      conditions = [ "service/syslogd/ready" ];
      command = "${pkgs.cronie}/bin/crond -n";
    };

    environment.etc = {
      "cron.d/btrfs-scrub".text = ''
        @monthly root ${pkgs.btrfs-progs}/bin/btrfs scrub start -B /
      '';
/*
      "cron.d/btrfs-prune-old-roots".text = ''
        0 4 * * 0 root ${pkgs.bash}/bin/bash ${../scripts/btrfs-prune-old-roots.sh} ${config.fileSystems."/".device}
      '';
*/
      "cron.d/fstrim".text = ''
        @monthly root ${pkgs.util-linux}/bin/fstrim -av
      '';
    };

    environment.systemPackages = [ pkgs.cronie ];
  };
}
