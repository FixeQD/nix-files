{ pkgs, ... }:
{
  home.packages = with pkgs; [
    gparted
    ntfs3g
    openrgb
    tailscale
    wireguard-tools
    spicetify-cli
    fwupd
    modprobed-db
  ];
}
