{ pkgs, ... }:
{
  home.packages = with pkgs; [
    gparted
    ntfs3g
    wireguard-tools
    spicetify-cli
    fwupd
    modprobed-db
    cpupower-gui
  ];
}
