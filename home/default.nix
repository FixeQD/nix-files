{ ... }:
{
  imports = [
    ./packages.nix
    ./programs.nix
    ./theme.nix
    ./secrets.nix
    ./zed.nix
    ./dotfiles.nix
  ];

  home = {
    username      = "fixeq";
    homeDirectory = "/home/fixeq";
    stateVersion  = "25.11";
  };

  xdg.enable          = true;
  xdg.userDirs.enable = true;
}
