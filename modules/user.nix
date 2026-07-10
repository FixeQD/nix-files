{
  pkgs,
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.modules.user;
  runtimeDirCmd = "/run/user/$(${pkgs.coreutils}/bin/id -u ${cfg.name})";
in
{
  options.modules.user = {
    enable = mkEnableOption "primary user and sudo";
    name = mkOption {
      type = types.str;
      description = "Primary user login name";
    };
  };

  config = mkIf cfg.enable {
    users.users.${cfg.name} = {
      isNormalUser = true;
      description = cfg.name;
      shell = pkgs.fish;
      passwordFile = "/etc/nixos-passwords/${cfg.name}";
      extraGroups = [
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
      runlevels = "2345";
      conditions = [ "service/seatd/ready" ];
      command = pkgs.writeShellScript "user-runtime-dir" ''
        dir="${runtimeDirCmd}"
        mkdir -p "$dir"
        chown ${cfg.name}:${config.users.users.${cfg.name}.group} "$dir"
        chmod 0700 "$dir"
      '';
    };

    environment.etc."profile.d/pipewire-session.sh" = mkIf config.programs.pipewire.enable {
      text = ''
        if [ -n "$XDG_RUNTIME_DIR" ] && [ ! -e "$XDG_RUNTIME_DIR/pipewire-session.lock" ]; then
          if ( set -o noclobber; : > "$XDG_RUNTIME_DIR/pipewire-session.lock" ) 2>/dev/null; then
            ${config.programs.pipewire.package}/bin/pipewire >/dev/null 2>&1 &
            ${config.programs.pipewire.package}/bin/pipewire-pulse >/dev/null 2>&1 &
            ${lib.optionalString config.programs.pipewire.wireplumber.enable "${config.programs.pipewire.wireplumber.package}/bin/wireplumber >/dev/null 2>&1 &"}
          fi
        fi
      '';
    };
  };
}
