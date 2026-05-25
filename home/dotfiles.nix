{ ... }:
{
  # Link entire .config directory from dotfiles
  home.file.".config" = {
    source = ./dotfiles/.config;
    recursive = true;
  };
}
