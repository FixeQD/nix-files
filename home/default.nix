{ username, ... }:
{
  imports = [
    ./packages.nix
    ./programs.nix
    ./theme.nix
    ./secrets-keys.nix
    ./zed.nix
    ./dotfiles.nix
  ];

  home = {
    inherit username;
    homeDirectory = "/home/${username}";
    stateVersion  = "25.11";
  };

  xdg.enable          = true;
  xdg.userDirs.enable = true;
  xdg.userDirs.setSessionVariables = true;
}
