{ pkgs, lib, config, ... }:
with lib;
let cfg = config.modules.user; in
{
  options.modules.user = {
    enable = mkEnableOption "primary user and sudo";
    name   = mkOption {
      type        = types.str;
      description = "Primary user login name";
    };
  };

  config = mkIf cfg.enable {
    users.users.${cfg.name} = {
      isNormalUser = true;
      description  = cfg.name;
      shell        = pkgs.fish;
      extraGroups  = [
        "wheel"
        "seat"
        "storage"
        "power"
        "audio"
        "video"
        "optical"
        "network"
        "input"
        "docker"
        "libvirtd"
        "kvm"
        "adbusers"
      ];
    };

    programs.sudo.enable = true;

    services.udev.packages = [ pkgs.android-udev-rules ];
  };
}
