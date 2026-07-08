{ pkgs, lib, config, ... }:
with lib;
let cfg = config.modules.audio; in
{
  options.modules.audio.enable = mkEnableOption "PipeWire audio (community-modules programs.pipewire)";

  config = mkIf cfg.enable {
    programs.pipewire.enable = true;
    programs.pipewire.alsa.enable = true;

    environment.systemPackages = [
      pkgs.pavucontrol
    ];
  };
}
