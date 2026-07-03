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
      passwordFile = "/etc/nixos-passwords/${cfg.name}";
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

    users.users.root.passwordFile = "/etc/nixos-passwords/root";

    programs.sudo.enable = true;

    services.udev.packages = [ pkgs.android-udev-rules ];
  };
}
