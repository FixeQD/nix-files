{ zen-browser, anyrun, sops-nix, ... }:
{
  imports = [
    ./hardware.nix
    ./boot.nix
    ../../modules/base.nix
    ../../modules/locale.nix
    ../../modules/network.nix
    ../../modules/cron.nix
    ../../modules/performance.nix
    ../../modules/zram.nix
    ../../modules/audio.nix
    ../../modules/desktop.nix
    ../../modules/security.nix
    ../../modules/pam.nix
    ../../modules/user.nix
    ../../modules/virt.nix
    ../../modules/bluetooth.nix
  ];

  networking.hostName = "HP-ZBook";

  home-manager = {
    useGlobalPkgs   = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit zen-browser anyrun; };
    sharedModules = [
      sops-nix.homeManagerModules.sops
    ];
    users.fixeq = import ../../home/default.nix;
  };

  system.stateVersion = "25.11";
}
