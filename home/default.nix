{ username, ... }:
{
  imports = [
    ./packages.nix
    ./programs.nix
    ./theme.nix
    ./secrets.nix
    ./secrets-keys.nix
    ./zed.nix
    ./dotfiles.nix
    ./persistence.nix
  ];

  home = {
    inherit username;
    homeDirectory = "/home/${username}";
    stateVersion  = "25.11";
  };

  xdg.enable          = true;
  xdg.userDirs.enable = true;
}
