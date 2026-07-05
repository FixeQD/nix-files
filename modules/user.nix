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
    finit.services.pipewire = mkIf config.programs.pipewire.enable {
      description = "PipeWire multimedia daemon (user session)";
      runlevels   = "2345";
      conditions  = [ "service/seatd/ready" ];
      user        = cfg.name;
      command     = "${pkgs.pipewire}/bin/pipewire";
      notify      = "s6";
    };

    finit.services.wireplumber = mkIf (config.programs.pipewire.enable && config.programs.pipewire.wireplumber.enable) {
      description = "WirePlumber session manager (user session)";
      runlevels   = "2345";
      conditions  = [ "service/pipewire/ready" ];
      user        = cfg.name;
      command     = "${pkgs.wireplumber}/bin/wireplumber";
      notify      = "s6";
    };

    finit.services.pipewire-pulse = mkIf config.programs.pipewire.enable {
      description = "PipeWire PulseAudio replacement (user session)";
      runlevels   = "2345";
      conditions  = [ "service/pipewire/ready" ];
      user        = cfg.name;
      command     = "${pkgs.pipewire}/bin/pipewire-pulse";
    };
  };
}
