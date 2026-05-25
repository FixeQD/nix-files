{ pkgs, ... }:
{
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = true;

  environment.systemPackages = with pkgs; [
    # core
    btrfs-progs
    util-linux
    coreutils
    wget
    curl
    git
    neovim
    man-pages
    less
    # monitoring
    btop
    fastfetch
    usbutils
    pciutils
    lshw
    # tools
    ripgrep
    fd
    bat
    eza
    tree
    tokei
    fwupd
    # shell
    fish
    starship
    # terminal
    ghostty
    # nix
    nixd
  ];

  programs.fish.enable = true;
  users.defaultUserShell = pkgs.fish;

  nix = {
    settings = {
      experimental-features  = [ "nix-command" "flakes" ];
      auto-optimise-store    = true;
      warn-dirty             = false;
      max-jobs               = "auto";
    };
    gc = {
      automatic = true;
      dates     = "monthly";
      options   = "--delete-older-than 30d";
    };
  };
}
