{
  description = "finix config";

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

  outputs = { nixpkgs, finix, disko, home-manager, sops-nix, zen-browser, anyrun, ... }:
  let
    forSystem = system: nixpkgs.legacyPackages.${system};

    mkHost = { hostname, system ? "x86_64-linux", extraModules ? [ ] }:
      nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit zen-browser anyrun sops-nix; };
        modules = [
          finix.nixosModules.default
          disko.nixosModules.disko
          home-manager.nixosModules.home-manager
          sops-nix.nixosModules.sops
          ./hosts/${hostname}/default.nix
        ] ++ extraModules;
      };
  in
  {
    nixosConfigurations = {
      hp-zbook = mkHost { hostname = "hp-zbook"; };
    };

    apps.x86_64-linux.install = let
      pkgs = forSystem "x86_64-linux";
    in {
      type = "app";
      program = toString (pkgs.writeShellScript "install-hp-zbook" ''
        set -euo pipefail
        FLAKE_DIR="$(cd "$(dirname "$0")/../.." && pwd)"

        echo "==> [1/3] disko: partitioning /dev/nvme0n1"
        ${disko.packages.x86_64-linux.disko}/bin/disko \
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
