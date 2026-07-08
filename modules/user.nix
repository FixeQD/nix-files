{ pkgs, lib, config, ... }:
with lib;
let
  cfg = config.modules.user;
  runtimeDirCmd = "/run/user/$(${pkgs.coreutils}/bin/id -u ${cfg.name})";
  wrapWithRuntimeDir = cmd: ''
    ${pkgs.bash}/bin/bash -c 'export XDG_RUNTIME_DIR=${runtimeDirCmd}; exec ${cmd}'
  '';
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

    finit.tasks.user-runtime-dir = {
      description = "Create ${cfg.name}'s XDG_RUNTIME_DIR";
      runlevels   = "2345";
      conditions  = [ "service/seatd/ready" ];
      command     = pkgs.writeShellScript "user-runtime-dir" ''
        dir="${runtimeDirCmd}"
        mkdir -p "$dir"
        chown ${cfg.name}:${config.users.users.${cfg.name}.group} "$dir"
        chmod 0700 "$dir"
      '';
    };

    finit.services.pipewire = mkIf config.programs.pipewire.enable {
      description = "PipeWire multimedia daemon (user session)";
      runlevels   = "2345";
      conditions  = [ "service/seatd/ready" "task/user-runtime-dir/success" ];
      user        = cfg.name;
      command     = wrapWithRuntimeDir "${pkgs.pipewire}/bin/pipewire";
    };

    finit.services.wireplumber = mkIf (config.programs.pipewire.enable && config.programs.pipewire.wireplumber.enable) {
      description = "WirePlumber session manager (user session)";
      runlevels   = "2345";
      conditions  = [ "service/pipewire/ready" ];
      user        = cfg.name;
      command     = wrapWithRuntimeDir "${pkgs.wireplumber}/bin/wireplumber";
    };

    finit.services.pipewire-pulse = mkIf config.programs.pipewire.enable {
      description = "PipeWire PulseAudio replacement (user session)";
      runlevels   = "2345";
      conditions  = [ "service/pipewire/ready" ];
      user        = cfg.name;
      command     = wrapWithRuntimeDir "${pkgs.pipewire}/bin/pipewire-pulse";
    };
  };
}