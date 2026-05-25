{
  description = "finix config, currently only for my laptop";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    finix = {
      url = "github:finix-community/finix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dotfiles.url = "github:FixeQD/dotfiles";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    anyrun = {
      url = "github:anyrun-launcher/anyrun";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, finix, disko, home-manager, sops-nix, dotfiles, zen-browser, anyrun, ... }:
  let
    system = "x86_64-linux";
    pkgs   = nixpkgs.legacyPackages.${system};
  in
  {
    nixosConfigurations.hp-zbook = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit zen-browser anyrun dotfiles sops-nix; };
      modules = [
        finix.nixosModules.default
        disko.nixosModules.disko
        home-manager.nixosModules.home-manager
        sops-nix.nixosModules.sops
        ./hosts/hp-zbook/default.nix
      ];
    };

    apps.${system}.install = {
      type = "app";
      program = toString (pkgs.writeShellScript "install-hp-zbook" ''
        set -euo pipefail
        FLAKE_DIR="$(cd "$(dirname "$0")/../.." && pwd)"

        echo "==> [1/3] disko: partitioning /dev/nvme0n1"
        ${disko.packages.${system}.disko}/bin/disko \
          --mode destroy-format-mount \
          --flake "$FLAKE_DIR#hp-zbook"

        echo "==> [2/3] sbctl: creating Secure Boot keys"
        ${pkgs.sbctl}/bin/sbctl create-keys \
          --database-path /mnt/etc/secureboot/keys
        ${pkgs.sbctl}/bin/sbctl enroll-keys \
          --database-path /mnt/etc/secureboot/keys \
          --microsoft

        echo "==> [3/3] nixos-install"
        nixos-install \
          --flake "$FLAKE_DIR#hp-zbook" \
          --no-root-passwd \
          --no-channel-copy

        echo "==> Ready!"
      '');
    };
  };
}
