{ ... }:
{
  imports = [
    ./packages.nix
    ./programs.nix
    ./theme.nix
    ./secrets.nix
    ./zed.nix
  ];

  home = {
    username      = "fixeq";
    homeDirectory = "/home/fixeq";
    stateVersion  = "25.11";
  };

  dotfiles.locale = "pl";

  xdg.enable          = true;
  xdg.userDirs.enable = true;
}
