{ config, lib, ... }:
let
  xdg   = config.xdg.userDirs;
  home  = config.home.homeDirectory;
  rel   = path: lib.removePrefix "${home}/" path;
in
{
  home.persistence."/persistent" = {
    hideMounts = true;
    directories = [
      (rel xdg.download)
      (rel xdg.documents)
      (rel xdg.pictures)
      (rel xdg.videos)
      (rel xdg.music)
      ".ssh"
      ".gnupg"
      ".local/share/keyrings"
      ".local/share/direnv"
      ".config/sops"
    ];
  };
}
