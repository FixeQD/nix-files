{ pkgs, lib, config, ... }:
with lib;
let cfg = config.modules.desktop; in
{
  options.modules.desktop.enable = mkEnableOption "Hyprland desktop and seatd";

  config = mkIf cfg.enable {
    services.seatd.enable = true;

    programs.hyprland = {
      enable         = true;
    };

    environment.sessionVariables = {
      WLR_NO_HARDWARE_CURSORS             = "1";
      LIBVA_DRIVER_NAME                   = "nvidia";
      GBM_BACKEND                         = "nvidia-drm";
      __GLX_VENDOR_LIBRARY_NAME           = "nvidia";
      NVD_BACKEND                         = "direct";
      NIXOS_OZONE_WL                      = "1";
      MOZ_ENABLE_WAYLAND                  = "1";
      QT_QPA_PLATFORM                     = "wayland";
      QT_QPA_PLATFORMTHEME                = "qt6ct";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      ELECTRON_OZONE_PLATFORM_HINT        = "auto";
    };

    xdg.portal = {
      enable       = true;
      portals = [
        pkgs.xdg-desktop-portal-hyprland
        pkgs.xdg-desktop-portal-gtk
      ];
    };

    services.sddm.enable = true;
    services.sddm.settings = {
      DisplayServer = "wayland";
      Wayland.SessionDir = "/run/current-system/sw/share/wayland-sessions";
    };

    environment.pathsToLink = [
      "/share/wayland-sessions"
    ];
  };
}
