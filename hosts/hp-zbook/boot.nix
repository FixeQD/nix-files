{ pkgs, config, lib, ... }:

let
  # The disk device - defined in hardware.nix
  bootDisk = config.disko.devices.disk.main.device;

  # The EFI System Partition mount point
  efiMount = config.boot.loader.efi.efiSysMountPoint;

  # Root filesystem type - populated by disko
  rootFsType = config.fileSystems."/".fsType;

  # Root subvolume name - disko automatically appends "subvol=<name>" to options
  _rootMountOpts = config.fileSystems."/".options;
  _rootSubvolOpt = lib.findFirst (lib.hasPrefix "subvol=") null _rootMountOpts;
  rootSubvol      = if _rootSubvolOpt != null
                    then lib.removePrefix "subvol=" _rootSubvolOpt
                    else throw "boot.nix: subvol= not found in fileSystems.\"/\".options";

  # ── EFISTUB install hook ───────────────────────────────────────────────────

  efistubHook = pkgs.writeShellScript "efistub-install" ''
    set -euo pipefail

    BOOTSPEC="$1/boot.json"
    DISK="${bootDisk}"
    BOOT_DIR="${efiMount}/EFI/nixos"
    TIMESTAMP=$(${pkgs.coreutils}/bin/date +%s)
    CURRENT_KERNEL="$BOOT_DIR/kernel-$TIMESTAMP.efi"
    CURRENT_INITRD="$BOOT_DIR/initrd-$TIMESTAMP"

    PART_DEV=$(${pkgs.coreutils}/bin/df --output=source ${efiMount} | tail -n1)
    PART=$(${pkgs.systemd}/bin/udevadm info --query=property --name="$PART_DEV" \
      | sed -n 's/^ID_PART_ENTRY_NUMBER=//p')
    if [ -z "$PART" ]; then
      PART=$(${pkgs.coreutils}/bin/cat \
        "/sys/class/block/$(${pkgs.coreutils}/bin/basename "$PART_DEV")/partition" \
        2>/dev/null || true)
    fi

    # ─────────────────────────────────────────────────────────────────────────
    # Pre-flight validation
    # ─────────────────────────────────────────────────────────────────────────

    for tool in date basename; do
      if ! command -v "$tool" &>/dev/null; then
        echo "ERROR: required tool not found: $tool"
        exit 1
      fi
    done

    [ -r "$BOOTSPEC" ] || { echo "ERROR: boot.json not found at $BOOTSPEC"; exit 1; }
    [ -n "$DISK" ]     || { echo "ERROR: boot device is empty"; exit 1; }
    [ -n "$PART" ]     || { echo "ERROR: partition number is empty"; exit 1; }
    [ -b "$DISK" ]     || { echo "ERROR: boot device not found: $DISK"; exit 1; }

    # ─────────────────────────────────────────────────────────────────────────
    # Extract boot parameters
    # ─────────────────────────────────────────────────────────────────────────

    KERNEL=$(${pkgs.jq}/bin/jq -r '."org.nixos.bootspec.v1".kernel' "$BOOTSPEC")
    INITRD=$(${pkgs.jq}/bin/jq -r '."org.nixos.bootspec.v1".initrd' "$BOOTSPEC")
    INIT=$(${pkgs.jq}/bin/jq -r '."org.nixos.bootspec.v1".init' "$BOOTSPEC")
    PARAMS=$(${pkgs.jq}/bin/jq -r '."org.nixos.bootspec.v1".kernelParams | join(" ")' "$BOOTSPEC")

    [ -n "$KERNEL" ] || { echo "ERROR: kernel not found in boot.json"; exit 1; }
    [ -n "$INITRD" ] || { echo "ERROR: initrd not found in boot.json"; exit 1; }
    [ -n "$INIT" ]   || { echo "ERROR: init not found in boot.json"; exit 1; }
    [ -f "$KERNEL" ] || { echo "ERROR: kernel file not found: $KERNEL"; exit 1; }
    [ -f "$INITRD" ] || { echo "ERROR: initrd file not found: $INITRD"; exit 1; }

    # ─────────────────────────────────────────────────────────────────────────
    # Install kernel and initrd
    # ─────────────────────────────────────────────────────────────────────────

    mkdir -p "$BOOT_DIR"

    echo "==> Installing kernel and initrd (timestamp: $TIMESTAMP)"
    if ! install -m 0644 "$KERNEL" "$CURRENT_KERNEL"; then
      echo "ERROR: Failed to install kernel"
      exit 1
    fi
    if ! install -m 0644 "$INITRD" "$CURRENT_INITRD"; then
      echo "ERROR: Failed to install initrd"
      exit 1
    fi

    # ─────────────────────────────────────────────────────────────────────────
    # Sign kernel if Secure Boot is enabled
    # ─────────────────────────────────────────────────────────────────────────

    if [ -d /etc/secureboot/keys ]; then
      echo "==> sbctl: signing kernel"
      if ! ${pkgs.sbctl}/bin/sbctl sign "$CURRENT_KERNEL"; then
        echo "WARNING: sbctl signing failed, but continuing (Secure Boot may not work)"
      fi
    fi

    # ─────────────────────────────────────────────────────────────────────────
    # Manage boot entry generations
    # ─────────────────────────────────────────────────────────────────────────

    echo "==> Managing boot entry generations"

    ACTIVE_KERNEL_TS=$(${pkgs.efibootmgr}/bin/efibootmgr -v \
      | grep "Finix" \
      | grep -oP "kernel-[0-9]+" \
      | sed 's/kernel-//' \
      | sort -n \
      | tail -n1 || true)

    PREV=$(${pkgs.efibootmgr}/bin/efibootmgr \
      | grep -oP "(?<=Boot)[0-9A-F]+(?=[\* ]+Finix \(previous\))" || true)

    if [ -n "$PREV" ]; then
      echo "==> Removing old previous entry ($PREV)"
      if ! ${pkgs.efibootmgr}/bin/efibootmgr -q -b "$PREV" -B; then
        echo "WARNING: Failed to remove old boot entry, but continuing"
      fi
    fi

    for kernel_file in "$BOOT_DIR"/kernel-*.efi; do
      if [ -f "$kernel_file" ] && [ "$kernel_file" != "$CURRENT_KERNEL" ]; then
        TS=$(basename "$kernel_file" .efi | sed 's/kernel-//')
        if [ "$TS" != "$ACTIVE_KERNEL_TS" ]; then
          echo "==> Cleaning up orphaned file: $kernel_file"
          rm -f "$kernel_file"
          rm -f "$BOOT_DIR/initrd-$TS"
        fi
      fi
    done

    # Rename current "Finix" to "Finix (previous)"
    CURRENT=$(${pkgs.efibootmgr}/bin/efibootmgr \
      | grep -oP "(?<=Boot)[0-9A-F]+(?=[\* ]+Finix\b)(?!.*\(previous\))" || true)

    if [ -n "$CURRENT" ]; then
      echo "==> Promoting current entry to previous: $CURRENT"
      if ! ${pkgs.efibootmgr}/bin/efibootmgr -b "$CURRENT" -L "Finix (previous)"; then
        echo "WARNING: Failed to rename boot entry, but continuing"
      fi
    fi

    # ─────────────────────────────────────────────────────────────────────────
    # Create new primary boot entry
    # ─────────────────────────────────────────────────────────────────────────

    echo "==> Creating new primary entry ($DISK, partition $PART)"
    if ! ${pkgs.efibootmgr}/bin/efibootmgr \
      --quiet \
      --create \
      --disk "$DISK" \
      --part "$PART" \
      --label "Finix" \
      --loader '\EFI\nixos\kernel-'"$TIMESTAMP"'.efi' \
      --unicode "initrd=\EFI\nixos\initrd-$TIMESTAMP init=$INIT $PARAMS"; then
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

    supportedFilesystems.btrfs.enable = true;
  };

  boot.kernelModules = [
    "kvm-intel"
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
  ];

  environment.etc."modprobe.d/nvidia.conf".text = ''
    options nvidia NVreg_PreserveVideoMemoryAllocations=1
  '';

  # TEMPORARY: Enable emergency access for debugging purposes
  boot.initrd.emergencyAccess = true;

  boot.kernelParams = [
#    "quiet"
#    "loglevel=3"
    "rootflags=subvol=${rootSubvol}"
    "rootfstype=${rootFsType}"
    "zswap.enabled=0"
    "nvidia-drm.modeset=1"
  ];
}
