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

  # Keep this many Finix generations in NVRAM
  keepGenerations = 3;

  # ── EFISTUB install hook ───────────────────────────────────────────────────

  efistubHook = pkgs.writeShellScript "efistub-install" ''
    set -euo pipefail

    BOOTSPEC="$1/boot.json"
    BOOT_DIR="${efiMount}/EFI/nixos"
    TIMESTAMP=$(${pkgs.coreutils}/bin/date +%s)
    CURRENT_KERNEL="$BOOT_DIR/kernel-$TIMESTAMP.efi"
    CURRENT_INITRD="$BOOT_DIR/initrd-$TIMESTAMP"
    FINIX="${pkgs.finix-bootctl}/bin/finix-bootctl"

    # ─────────────────────────────────────────────────────────────────────────
    # Pre-flight validation
    # ─────────────────────────────────────────────────────────────────────────

    [ -r "$BOOTSPEC" ] || { echo "ERROR: boot.json not found at $BOOTSPEC"; exit 1; }
    [ -b "${bootDisk}" ] || { echo "ERROR: boot device not found: ${bootDisk}"; exit 1; }

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
    install -m 0644 "$KERNEL" "$CURRENT_KERNEL"
    install -m 0644 "$INITRD" "$CURRENT_INITRD"

    # ─────────────────────────────────────────────────────────────────────────
    # Sign kernel if Secure Boot is enabled
    # ─────────────────────────────────────────────────────────────────────────

    if [ -d /etc/secureboot/keys ]; then
      echo "==> sbctl: signing kernel"
      ${pkgs.sbctl}/bin/sbctl sign "$CURRENT_KERNEL" || \
        echo "WARNING: sbctl signing failed, but continuing (Secure Boot may not work)"
    fi

    # ─────────────────────────────────────────────────────────────────────────
    # Create new primary boot entry (finix-bootctl puts it first in BootOrder)
    # ─────────────────────────────────────────────────────────────────────────

    echo "==> Creating new primary entry (timestamp $TIMESTAMP)"
    NEW_ID=$("$FINIX" create "${efiMount}" \
      '\EFI\nixos\kernel-'"$TIMESTAMP"'.efi' \
      "initrd=\EFI\nixos\initrd-$TIMESTAMP init=$INIT $PARAMS" \
      "$TIMESTAMP")
    echo "==> Created Boot$NEW_ID"

    # ─────────────────────────────────────────────────────────────────────────
    # Prune old generations
    # ─────────────────────────────────────────────────────────────────────────

    mapfile -t GENERATIONS < <("$FINIX" list)   # lines: "<id-hex> <timestamp>", newest first
    echo "==> ''${#GENERATIONS[@]} Finix generation(s) in NVRAM"

    KEEP_TIMESTAMPS=()
    for line in "''${GENERATIONS[@]:0:${toString keepGenerations}}"; do
      KEEP_TIMESTAMPS+=("$(${pkgs.gawk}/bin/awk '{print $2}' <<<"$line")")
    done

    declare -A PRUNE_IDS
    if [ "''${#GENERATIONS[@]}" -gt "${toString keepGenerations}" ]; then
      for line in "''${GENERATIONS[@]:${toString keepGenerations}}"; do
        id=$(${pkgs.gawk}/bin/awk '{print $1}' <<<"$line")
        ts=$(${pkgs.gawk}/bin/awk '{print $2}' <<<"$line")
        "$FINIX" delete "$id"
        PRUNE_IDS["$ts"]="$id"
      done
    fi

    is_kept_timestamp() {
      local needle="$1"
      for ts in "''${KEEP_TIMESTAMPS[@]}"; do
        [ "$ts" = "$needle" ] && return 0
      done
      return 1
    }

    is_seen_timestamp() {
      local needle="$1"
      for ts in "''${ORPHAN_TIMESTAMPS[@]}"; do
        [ "$ts" = "$needle" ] && return 0
      done
      return 1
    }

    ORPHAN_TIMESTAMPS=()
    for f in "$BOOT_DIR"/kernel-*.efi "$BOOT_DIR"/initrd-*; do
      [ -e "$f" ] || continue
      base=$(basename "$f")
      file_ts="''${base#*-}"
      file_ts="''${file_ts%.efi}"
      if ! is_kept_timestamp "$file_ts" && ! is_seen_timestamp "$file_ts"; then
        ORPHAN_TIMESTAMPS+=("$file_ts")
      fi
    done

    for ts in "''${ORPHAN_TIMESTAMPS[@]}"; do
      if [ -n "''${PRUNE_IDS[$ts]:-}" ]; then
        echo "==> Removing orphaned ESP files kernel-$ts.efi + initrd-$ts (ts $ts, removed matching Boot''${PRUNE_IDS[$ts]} NVRAM entry)"
      else
        echo "==> Removing orphaned ESP files kernel-$ts.efi + initrd-$ts (ts $ts, no matching NVRAM entry)"
      fi
      rm -f "$BOOT_DIR/kernel-$ts.efi" "$BOOT_DIR/initrd-$ts"
    done

    echo "==> EFISTUB setup complete"
  '';
in
{
  boot.kernelPackages = pkgs.linuxPackages_zen;

  boot.loader.efi = {
    canTouchEfiVariables = true;
    efiSysMountPoint = "/boot";
  };

  boot.loader.script = {
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

  boot.kernelParams = [
    "quiet"
    "loglevel=3"
    "rootflags=subvol=${rootSubvol}"
    "rootfstype=${rootFsType}"
    "zswap.enabled=0"
    "nvidia-drm.modeset=1"
  ];
}
