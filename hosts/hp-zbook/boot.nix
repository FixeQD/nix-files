{ pkgs, ... }:

let
  efistubHook = pkgs.writeShellScript "efistub-install" ''
    set -euo pipefail

    BOOTSPEC="$1/boot.json"

    KERNEL=$(${pkgs.jq}/bin/jq -r '."org.nixos.bootspec.v1".kernel'               "$BOOTSPEC")
    INITRD=$(${pkgs.jq}/bin/jq -r '."org.nixos.bootspec.v1".initrd'               "$BOOTSPEC")
    PARAMS=$(${pkgs.jq}/bin/jq -r '."org.nixos.bootspec.v1".kernelParams | join(" ")' "$BOOTSPEC")

    mkdir -p /boot/EFI/nixos

    install -m 0644 "$KERNEL" /boot/EFI/nixos/kernel.efi
    install -m 0644 "$INITRD" /boot/EFI/nixos/initrd

    # Podpisz jeśli klucze sbctl już istnieją (po sbctl create-keys)
    if [ -d /etc/secureboot/keys ]; then
      echo "==> sbctl: signing kernel.efi"
      ${pkgs.sbctl}/bin/sbctl sign /boot/EFI/nixos/kernel.efi
    fi

    # Usuń stary wpis Finix z efibootmgr
    OLD=$(${pkgs.efibootmgr}/bin/efibootmgr \
      | grep -oP "(?<=Boot)[0-9A-F]+(?=\* Finix)" || true)
    [ -n "$OLD" ] && ${pkgs.efibootmgr}/bin/efibootmgr -q -b "$OLD" -B

    # Utwórz nowy wpis EFISTUB
    ${pkgs.efibootmgr}/bin/efibootmgr \
      --quiet \
      --create \
      --disk /dev/nvme0n1 \
      --part 1 \
      --label "Finix" \
      --loader '\EFI\nixos\kernel.efi' \
      --unicode "initrd=\EFI\nixos\initrd $PARAMS"

    echo "==> EFISTUB entry updated."
  '';
in
{
  boot.kernelPackages = pkgs.linuxPackages_zen;

  boot.loader.efi = {
    canTouchEfiVariables = true;
    efiSysMountPoint = "/boot";
  };

  boot.loader.external = {
    enable = true;
    installHook = efistubHook;
  };

  boot.initrd = {
    availableKernelModules = [
      "nvme"
      "xhci_pci"
      "ahci"
      "usb_storage"
      "sd_mod"
      "rtsx_pci_sdmmc"
    ];
    kernelModules = [ "i915" ];
  };

  boot.kernelModules = [
    "kvm-intel"
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
  ];

  boot.extraModprobeConfig = ''
    options nvidia-drm modeset=1
    options nvidia NVreg_PreserveVideoMemoryAllocations=1
  '';

  boot.kernelParams = [
    "quiet"
    "loglevel=3"
    "rootflags=subvol=@"
    "rootfstype=btrfs"
    "zswap.enabled=0"
    "nvidia-drm.modeset=1"
    # resume= ustawiane przez disko (resumeDevice = true w hardware.nix)
  ];
}
