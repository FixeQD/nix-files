{ lib, config, pkgs, ... }:
with lib;
let cfg = config.modules.zram; in
{
  options.modules.zram.enable = mkEnableOption "zram swap with zstd";

  config = mkIf cfg.enable {
    boot.kernelModules = [ "zram" ];

    finit.tasks.zram-setup = {
      description = "Setup zram swap device";
      runlevels = "S";
      command = pkgs.writeShellScript "zram-setup" ''
        RAM_KB=$(awk '/MemTotal/ { print $2 }' /proc/meminfo)
        ZRAM_KB=$((RAM_KB / 2))

        modprobe zram num_devices=1

        echo zstd > /sys/block/zram0/comp_algorithm
        echo "$((ZRAM_KB * 1024))" > /sys/block/zram0/disksize

        mkswap /dev/zram0
        swapon -p 5 /dev/zram0
      '';
    };
  };
}
