{ pkgs, config, ... }:

let
  bootDevice = config.disko.devices.disk.main.device;
  efistubHook = pkgs.writeShellScript "efistub-install" ''
    set -euo pipefail

    BOOTSPEC="$1/boot.json"
    DISK="${bootDevice}"
    PART="1"
    BOOT_DIR="/boot/EFI/nixos"
    TIMESTAMP=$(${pkgs.coreutils}/bin/date +%s)
    CURRENT_KERNEL="$BOOT_DIR/kernel-$TIMESTAMP.efi"
    CURRENT_INITRD="$BOOT_DIR/initrd-$TIMESTAMP"

    # Validate inputs
    [ -r "$BOOTSPEC" ] || { echo "ERROR: boot.json not found at $BOOTSPEC"; exit 1; }
    [ -n "$DISK" ] || { echo "ERROR: boot device is empty"; exit 1; }

    KERNEL=$(${pkgs.jq}/bin/jq -r '."org.nixos.bootspec.v1".kernel'               "$BOOTSPEC")
    INITRD=$(${pkgs.jq}/bin/jq -r '."org.nixos.bootspec.v1".initrd'               "$BOOTSPEC")
    PARAMS=$(${pkgs.jq}/bin/jq -r '."org.nixos.bootspec.v1".kernelParams | join(" ")' "$BOOTSPEC")

    [ -n "$KERNEL" ] || { echo "ERROR: kernel not found in boot.json"; exit 1; }
    [ -n "$INITRD" ] || { echo "ERROR: initrd not found in boot.json"; exit 1; }

    mkdir -p "$BOOT_DIR"

    # Install current kernel and initrd with timestamp
    echo "==> Installing kernel and initrd (timestamp: $TIMESTAMP)"
    install -m 0644 "$KERNEL" "$CURRENT_KERNEL"
    install -m 0644 "$INITRD" "$CURRENT_INITRD"

    # Sign if Secure Boot keys exist
    if [ -d /etc/secureboot/keys ]; then
      echo "==> sbctl: signing kernel"
      if ! ${pkgs.sbctl}/bin/sbctl sign "$CURRENT_KERNEL"; then
        echo "WARNING: sbctl signing failed, but continuing (Secure Boot may not work)"
      fi
    fi

    # Rotate old "previous" entry: current -> previous, then cleanup
    echo "==> Managing boot entry generations"

    # Find and remove old "Finix (previous)" entry + its orphaned files
    PREV=$(${pkgs.efibootmgr}/bin/efibootmgr \
      | grep -oP "(?<=Boot)[0-9A-F]+(?=\* Finix \(previous\))" || true)

    if [ -n "$PREV" ]; then
      echo "==> Removing old previous entry ($PREV)"
      ${pkgs.efibootmgr}/bin/efibootmgr -q -b "$PREV" -B || true

      # Clean up orphaned kernel/initrd files
      for kernel in "$BOOT_DIR"/kernel-*.efi; do
        if [ -f "$kernel" ] && [ "$kernel" != "$CURRENT_KERNEL" ]; then
          rm -f "$kernel"
          # Also remove corresponding initrd
          KBASE=$(basename "$kernel" .efi)
          rm -f "$BOOT_DIR/$KBASE"
        fi
      done
    fi

    # Rename current "Finix" to "Finix (previous)"
    CURRENT=$(${pkgs.efibootmgr}/bin/efibootmgr \
      | grep -oP "(?<=Boot)[0-9A-F]+(?=\* Finix)(?!\s\(previous\))" || true)

    if [ -n "$CURRENT" ]; then
      echo "==> Promoting current entry to previous: $CURRENT"
      ${pkgs.efibootmgr}/bin/efibootmgr -b "$CURRENT" -L "Finix (previous)" || true
    fi

    # Create new current EFISTUB entry
    echo "==> Creating new primary entry ($DISK, partition $PART)"
    if ! ${pkgs.efibootmgr}/bin/efibootmgr \
      --quiet \
      --create \
      --disk "$DISK" \
      --part "$PART" \
      --label "Finix" \
      --loader '\EFI\nixos\kernel-'"$TIMESTAMP"'.efi' \
      --unicode "initrd=\EFI\nixos\initrd-$TIMESTAMP $PARAMS"; then
      echo "ERROR: Failed to create boot entry!"
      exit 1
    fi

    echo "==> Boot entries:"
    ${pkgs.efibootmgr}/bin/efibootmgr | grep -E "Finix|^BootOrder"
    echo "==> EFISTUB setup complete (rollback available via \"Finix (previous)\")"
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
  ];
}
