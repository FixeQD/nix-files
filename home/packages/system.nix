{ pkgs, ... }:
{
  home.packages = with pkgs; [
    gparted
    ntfs3g
    openrgb
    wireguard-tools
    spicetify-cli
    fwupd
    modprobed-db
    cpupower-gui
  ];
}
