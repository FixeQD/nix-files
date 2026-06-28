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

    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, finix, disko, home-manager, sops-nix, zen-browser, anyrun, impermanence, ... }:
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
          impermanence.nixosModules.impermanence
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

        echo "==> [1/4] disko: partitioning /dev/nvme0n1"
        ${disko.packages.x86_64-linux.disko}/bin/disko \
          --mode destroy-format-mount \
          --flake "$FLAKE_DIR#hp-zbook"

        echo "==> [2/4] sops: installing age key"
        AGE_KEY_DIR="/mnt/persistent/.config/sops/age"
        mkdir -p "$AGE_KEY_DIR"
        if [ -f "$HOME/.config/sops/age/keys.txt" ]; then
          cp "$HOME/.config/sops/age/keys.txt" "$AGE_KEY_DIR/keys.txt"
          echo "    copied from $HOME/.config/sops/age/keys.txt"
        else
          echo    "    keys.txt not found at default location."
          printf  "    Paste age private key, then Ctrl+D: "
          cat > "$AGE_KEY_DIR/keys.txt"
          echo
        fi
        chmod 600 "$AGE_KEY_DIR/keys.txt"

        echo "==> [3/4] sbctl: creating Secure Boot keys"
        ${pkgs.sbctl}/bin/sbctl create-keys \
          --database-path /mnt/etc/secureboot/keys
        ${pkgs.sbctl}/bin/sbctl enroll-keys \
          --database-path /mnt/etc/secureboot/keys \
          --microsoft

        echo "==> [4/4] nixos-install"
        nixos-install \
          --flake "$FLAKE_DIR#hp-zbook" \
          --no-root-passwd \
          --no-channel-copy

        echo "==> Ready!"
      '');
    };
  };
}
