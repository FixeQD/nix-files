{
  description = "finix config";

  inputs = {
    # TEMPORARY: On `master` branch
    nixpkgs.url = "github:NixOS/nixpkgs";

    finix.url = "github:FixeQD/finix/dinit";
    community-modules.url = "github:FixeQD/finix-community-modules";
    finix-dinit-modules.url = "github:willowispll/dinit-modules";

    disko = {
      url = "github:nix-community/disko";
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

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    awww = {
      url = "git+https://codeberg.org/LGFae/awww";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      finix,
      community-modules,
      finix-dinit-modules,
      disko,
      sops-nix,
      zen-browser,
      spicetify-nix,
      awww,
      ...
    }:
    let
      mkHost =
        {
          hostname,
          system ? "x86_64-linux",
          extraModules ? [ ],
        }:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
            overlays = [
              sops-nix.overlays.default
              (import ./pkgs)
            ];
          };
        in
        finix.lib.finixSystem {
          inherit (pkgs) lib;
          modules = [
            { nixpkgs.pkgs = nixpkgs.lib.mkDefault pkgs; }
            { _module.args = { inherit zen-browser spicetify-nix awww; }; }
            disko.nixosModules.disko
            community-modules.nixosModules.home-manager
            finix.nixosModules.pipewire
            finix.nixosModules.wireplumber
            community-modules.nixosModules.nix-ld
            community-modules.nixosModules.openrgb
            ./modules/sops
            finix.nixosModules.bluetooth
            finix.nixosModules.docker
            finix.nixosModules.dinit
            finix-dinit-modules.nixosModules.getty
            finix.nixosModules.hyprland
            finix.nixosModules.xwayland-satellite
            finix.nixosModules.sudo
            finix-dinit-modules.nixosModules.sysklogd
            finix-dinit-modules.nixosModules.mdevd
            finix-dinit-modules.nixosModules.pid1
            finix.nixosModules.iwd
            finix.nixosModules.dhcpcd
            finix.nixosModules.sddm
            finix.nixosModules.zzz
            finix.nixosModules.brightnessctl
            finix.nixosModules.fwupd
            ./hosts/${hostname}/default.nix
            {
              finit.enable = false;
              services.udev.enable = false;
              services.mdevd-dinit.enable = true;
              services.sysklogd-dinit.enable = true;
              services.getty-dinit.enable = true;
            }
          ]
          ++ extraModules;
        };
    in
    {
      nixosConfigurations = {
        hp-zbook = mkHost { hostname = "hp-zbook"; };
      };

      apps.x86_64-linux.install =
        let
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
        in
        {
          type = "app";
          program = toString (
            pkgs.writeShellScript "install-hp-zbook" ''
              export DISKO_BIN="${disko.packages.x86_64-linux.disko}/bin/disko"
              export SBCTL_BIN="${pkgs.sbctl}/bin/sbctl"
              export MKPASSWD_BIN="${pkgs.mkpasswd}/bin/mkpasswd"
              export FLAKE_HOST="hp-zbook"
              export PRIMARY_USER="fixeq"
              source ${./install.sh}
            ''
          );
        };

      apps.x86_64-linux.resume-install =
        let
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
        in
        {
          type = "app";
          program = toString (
            pkgs.writeShellScript "resume-install-hp-zbook" ''
              export DISKO_BIN="${disko.packages.x86_64-linux.disko}/bin/disko"
              export SBCTL_BIN="${pkgs.sbctl}/bin/sbctl"
              export MKPASSWD_BIN="${pkgs.mkpasswd}/bin/mkpasswd"
              export FLAKE_HOST="hp-zbook"
              export PRIMARY_USER="fixeq"
              export DISKO_MODE="mount"
              source ${./install.sh}
            ''
          );
        };
    };
}
