{ pkgs, ... }:
{
  fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      nerd-fonts.jetbrains-mono
      liberation_ttf
      dejavu_fonts
      material-symbols
      google-fonts
    ];

    fontconfig = {
      enable = true;

      defaultFonts = {
        serif      = [ "Noto Serif" ];
        sansSerif  = [ "Noto Sans" ];
        monospace  = [ "JetBrainsMono Nerd Font" ];
        emoji      = [ "Noto Color Emoji" ];
      };
    };
  };
}
