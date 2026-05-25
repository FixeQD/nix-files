{ pkgs, ... }:
{
  # ── GTK ───────────────────────────────────────────────────────────────────
  gtk = {
    enable = true;

    theme = {
      name    = "Breeze";
      package = pkgs.kdePackages.breeze-gtk;
    };

    iconTheme = {
      name    = "breeze";
      package = pkgs.kdePackages.breeze-icons;
    };

    cursorTheme = {
      name    = "Bibata-Modern-Ice";
      package = pkgs.bibata-cursors;
      size    = 24;
    };

    font = {
      name    = "Noto Sans";
      size    = 10;
      package = pkgs.noto-fonts;
    };

    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
      gtk-decoration-layout             = "icon:minimize,maximize,close";
      gtk-enable-animations             = true;
      gtk-enable-input-method-menu      = true;
      gtk-enable-mnemonics              = true;
    };

    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
      gtk-decoration-layout             = "icon:minimize,maximize,close";
      gtk-enable-input-method-menu      = true;
      gtk-enable-mnemonics              = true;
    };
  };

  # ── Qt ────────────────────────────────────────────────────────────────────
  qt = {
    enable         = true;
    platformTheme.name = "kde";
    style = {
      name    = "Breeze";
      package = pkgs.kdePackages.breeze;
    };
  };

  # ── Cursor (system-wide przez X resources) ────────────────────────────────
  home.pointerCursor = {
    name    = "Bibata-Modern-Ice";
    package = pkgs.bibata-cursors;
    size    = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  # ── Fonty ─────────────────────────────────────────────────────────────────
  home.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-emoji
  ];
}
