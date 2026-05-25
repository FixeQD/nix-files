{ pkgs, config, ... }:

let
  bootDevice = config.disko.devices.disk.main.device;
  efistubHook = pkgs.writeShellScript "efistub-install" ''
    set -euo pipefail

    BOOTSPEC="$1/boot.json"
    DISK="${bootDevice}"
    PART="1"

    # Validate inputs
    [ -r "$BOOTSPEC" ] || { echo "ERROR: boot.json not found at $BOOTSPEC"; exit 1; }
    [ -n "$DISK" ] || { echo "ERROR: boot device is empty"; exit 1; }

    KERNEL=$(${pkgs.jq}/bin/jq -r '."org.nixos.bootspec.v1".kernel'               "$BOOTSPEC")
    INITRD=$(${pkgs.jq}/bin/jq -r '."org.nixos.bootspec.v1".initrd'               "$BOOTSPEC")
    PARAMS=$(${pkgs.jq}/bin/jq -r '."org.nixos.bootspec.v1".kernelParams | join(" ")' "$BOOTSPEC")

    [ -n "$KERNEL" ] || { echo "ERROR: kernel not found in boot.json"; exit 1; }
    [ -n "$INITRD" ] || { echo "ERROR: initrd not found in boot.json"; exit 1; }

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
    if [ -n "$OLD" ]; then
      echo "==> efibootmgr: removing old Finix entry ($OLD)"
      ${pkgs.efibootmgr}/bin/efibootmgr -q -b "$OLD" -B
    fi

    # Utwórz nowy wpis EFISTUB
    echo "==> efibootmgr: creating new entry ($DISK, partition $PART)"
    ${pkgs.efibootmgr}/bin/efibootmgr \
      --quiet \
      --create \
      --disk "$DISK" \
      --part "$PART" \
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
