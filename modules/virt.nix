{ pkgs, lib, config, ... }:
with lib;
let cfg = config.modules.virt; in
{
  options.modules.virt.enable = mkEnableOption "Docker and libvirt";

  config = mkIf cfg.enable {
    virtualisation.docker = {
      enable = true;
      autoPrune.enable = false;
    };

    virtualisation.libvirtd = {
      enable = true;
      qemu = {
        package     = pkgs.qemu;
        ovmf.enable = true;
        swtpm.enable = true;
      };
    };

    finit.services.docker = {
      description = "Docker daemon";
      runlevels   = "2345";
      conditions  = [ "service/syslogd/ready" ];
      command     = "${pkgs.docker}/bin/dockerd";
    };

    finit.services.libvirtd = {
      description = "libvirt virtualisation daemon";
      runlevels   = "2345";
      conditions  = [ "service/syslogd/ready" ];
      command     = "${pkgs.libvirt}/bin/libvirtd";
    };

    programs.virt-manager.enable = true;

    environment.systemPackages = with pkgs; [
      qemu
      virt-viewer
      spice-gtk
      virtiofsd
    ];
  };
}
