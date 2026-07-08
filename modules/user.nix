{ pkgs, lib, config, ... }:
with lib;
let
  cfg = config.modules.user;
  runtimeDir = "/run/user/${toString config.users.users.${cfg.name}.uid}";
in
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

    finit.tmpfiles.rules = [
      "d ${runtimeDir} 0700 ${cfg.name} ${config.users.users.${cfg.name}.group} -"
    ];

    finit.services.pipewire = mkIf config.programs.pipewire.enable {
      description = "PipeWire multimedia daemon (user session)";
      runlevels   = "2345";
      conditions  = [ "service/seatd/ready" "task/tmpfiles-setup/success" ];
      user        = cfg.name;
      environment = { XDG_RUNTIME_DIR = runtimeDir; };
      command     = "${pkgs.pipewire}/bin/pipewire";
    };

    finit.services.wireplumber = mkIf (config.programs.pipewire.enable && config.programs.pipewire.wireplumber.enable) {
      description = "WirePlumber session manager (user session)";
      runlevels   = "2345";
      conditions  = [ "service/pipewire/ready" ];
      user        = cfg.name;
      environment = { XDG_RUNTIME_DIR = runtimeDir; };
      command     = "${pkgs.wireplumber}/bin/wireplumber";
    };

    finit.services.pipewire-pulse = mkIf config.programs.pipewire.enable {
      description = "PipeWire PulseAudio replacement (user session)";
      runlevels   = "2345";
      conditions  = [ "service/pipewire/ready" ];
      user        = cfg.name;
      environment = { XDG_RUNTIME_DIR = runtimeDir; };
      command     = "${pkgs.pipewire}/bin/pipewire-pulse";
    };
  };
}
