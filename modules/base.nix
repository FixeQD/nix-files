{ pkgs, lib, config, ... }:
with lib;
let cfg = config.modules.base; in
{
  options.modules.base.enable = mkEnableOption "core packages and Nix settings";

  config = mkIf cfg.enable {
    # TEMP: pkgs.microcode-intel currently fails to build on this nixpkgs
    # pin (unpack phase: "find: 'lib/firmware': No such file or directory").
    hardware.firmware = [ pkgs.linux-firmware ];

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
