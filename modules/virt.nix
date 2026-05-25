{ pkgs, ... }:
{
  # Docker
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };

  # libvirt + QEMU
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
}
