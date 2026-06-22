{ lib, config, ... }:
with lib;
let cfg = config.modules.zram; in
{
  options.modules.zram.enable = mkEnableOption "zram swap with zstd";

  config = mkIf cfg.enable {
    zramSwap = {
      enable = true;
      algorithm = "zstd";
      memoryPercent = 50;
    };
  };
}
