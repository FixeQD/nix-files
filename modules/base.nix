{ pkgs, lib, config, ... }:
with lib;
let cfg = config.modules.base; in
{
  options.modules.base.enable = mkEnableOption "core packages and Nix settings";

  config = mkIf cfg.enable {
    hardware.firmware = [ pkgs.linux-firmware pkgs.microcode-intel ];

    environment.systemPackages = with pkgs; [
      btrfs-progs
      util-linux
      coreutils
      wget
      curl
      git
      neovim
      man-pages
      less
      btop
      fastfetch
      usbutils
      pciutils
      lshw
      ripgrep
      fd
      bat
      eza
      tree
      tokei
      fwupd
      fish
      starship
      ghostty
      nixd
    ];

    programs.fish.enable = true;
    users.defaultUserShell = pkgs.fish;

    services.nix-daemon = {
      enable = true;
      settings = {
        experimental-features = [ "nix-command" "flakes" ];
        auto-optimise-store   = true;
        warn-dirty            = false;
        max-jobs              = "auto";
      };
    };
  };
}
