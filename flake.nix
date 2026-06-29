{
  description = "finix config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";

    finix.url = "github:FixeQD/finix";

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
  };

  outputs = { nixpkgs, finix, disko, home-manager, sops-nix, zen-browser, ... }:
  let
    mkHost = { hostname, system ? "x86_64-linux", extraModules ? [ ] }:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      in
      finix.lib.finixSystem {
        inherit (pkgs) lib;
        modules = [
          { nixpkgs.pkgs = nixpkgs.lib.mkDefault pkgs; }
          { _module.args = { inherit zen-browser sops-nix; }; }
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
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in {
      type = "app";
      program = toString (pkgs.writeShellScript "install-hp-zbook" ''
        set -euo pipefail
        FLAKE_DIR="$(pwd)"

        echo "==> [1/4] disko: partitioning /dev/nvme0n1"
        ${disko.packages.x86_64-linux.disko}/bin/disko \
          --mode destroy,format,mount \
          --flake "$FLAKE_DIR#hp-zbook"

        echo "==> [2/4] sops: installing age key"
        AGE_KEY_DIR="/mnt/etc/sops/age"
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
