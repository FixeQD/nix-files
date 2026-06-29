{ pkgs, lib, config, ... }:
with lib;
let cfg = config.modules.virt; in
{
  options.modules.virt.enable = mkEnableOption "Docker and libvirt";

  config = mkIf cfg.enable {
    services.docker = {
      enable = true;
      prune.enable = false;
    };

    virtualisation.libvirtd = {
      enable = true;
      qemu = {
        package     = pkgs.qemu;
        ovmf.enable = true;
        swtpm.enable = true;
      };
    };

    finit.services.libvirtd = {
      description = "libvirt virtualisation daemon";
      runlevels   = "2345";
      conditions  = [ "service/syslogd/ready" ];
      command     = "${pkgs.libvirt}/bin/libvirtd";
    };

    environment.systemPackages = with pkgs; [
      virt-manager
      qemu
      virt-viewer
      spice-gtk
      virtiofsd
    ];
  };
}
