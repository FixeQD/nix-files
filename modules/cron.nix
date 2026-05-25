{ pkgs, ... }:
{
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

    "cron.d/fstrim".text = ''
      @monthly root ${pkgs.util-linux}/bin/fstrim -av
    '';
  };

  environment.systemPackages = [ pkgs.cronie ];
}
