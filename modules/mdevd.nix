{ pkgs, lib, config, ... }:
with lib;
let cfg = config.modules.mdevd; in
{
  options.modules.mdevd.enable = mkEnableOption "mdevd device manager";

  config = mkIf cfg.enable {
    services.mdevd = {
      enable = true;

      # Rebroadcast kernel uevents to netlink group 4 so that libudev-zero consumers can see device events
      nlgroups = 4;
    };

    services.gardendevd.enable = true;
    services.gardendevd.debug = true;

    environment.systemPackages = with pkgs; [
      mdevd
      gardendevd
    ];
  };
}
