{ pkgs, lib, config, ... }:
with lib;
let cfg = config.modules.virt; in
{
  options.modules.virt.enable = mkEnableOption "Docker and libvirt";

  config = mkIf cfg.enable {
    virtualisation.docker = {
      enable = true;
      autoPrune.enable = true;
    };

    virtualisation.libvirtd = {
      enable = true;
      qemu = {
        package    = pkgs.qemu;
        ovmf.enable = true;
        swtpm.enable = true;
      };
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
