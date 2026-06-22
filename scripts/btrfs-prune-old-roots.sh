#!/usr/bin/env bash
set -euo pipefail

BTRFS_DEV="${1:-}"
if [ -z "$BTRFS_DEV" ] || [ ! -b "$BTRFS_DEV" ]; then
  echo "btrfs-prune: missing or invalid device: $BTRFS_DEV"
  exit 1
fi

MNT=$(mktemp -d)
trap 'umount "$MNT" 2>/dev/null || true; rmdir "$MNT" 2>/dev/null || true' EXIT

mount -t btrfs "$BTRFS_DEV" "$MNT"

if [ ! -d "$MNT/@_old" ]; then
  echo "btrfs-prune: no @_old directory"
  exit 0
fi

NOW=$(date +%s)
THIRTY_DAYS=$((30 * 86400))
PRUNED=0

for snap in "$MNT/@_old"/*/; do
  snap="${snap%/}"
  [ -d "$snap" ] || continue

  name=$(basename "$snap")
  snap_epoch=$(date -d "$(echo "$name" | sed 's/-/ /3')" +%s 2>/dev/null) || continue
  age=$((NOW - snap_epoch))

  if [ "$age" -gt "$THIRTY_DAYS" ]; then
    echo "btrfs-prune: deleting $name (${age}s old)"
    btrfs subvolume delete "$snap"
    PRUNED=$((PRUNED + 1))
  fi
done

echo "btrfs-prune: pruned $PRUNED old root snapshots"
