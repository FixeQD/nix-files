#!/usr/bin/env bash
# Installer for the hp-zbook host. Invoked via `nix run .#install`,
# which exports DISKO_BIN / SBCTL_BIN / FLAKE_HOST and sources this file.
# Not meant to be run standalone without those set.
set -euo pipefail

: "${DISKO_BIN:?DISKO_BIN must be set}"
: "${SBCTL_BIN:?SBCTL_BIN must be set}"
: "${FLAKE_HOST:=hp-zbook}"
: "${DISKO_MODE:=destroy,format,mount}"

FLAKE_DIR="$(pwd)"

echo "==> [1/4] disko (mode: $DISKO_MODE): /dev/nvme0n1"
"$DISKO_BIN" \
  --mode "$DISKO_MODE" \
  --flake "$FLAKE_DIR#$FLAKE_HOST"

echo "==> [2/4] sops: installing age key"
AGE_KEY_DIR="/mnt/etc/sops/age"
mkdir -p "$AGE_KEY_DIR"
if [ -f "$HOME/.config/sops/age/keys.txt" ]; then
  cp "$HOME/.config/sops/age/keys.txt" "$AGE_KEY_DIR/keys.txt"
  echo "    copied from $HOME/.config/sops/age/keys.txt"
else
  echo    "    keys.txt not found at default location."
  printf  "    Paste age private key, then Ctrl+D: "
  stty -echo
  trap 'stty echo' EXIT
  : > "$AGE_KEY_DIR/keys.txt"
  while IFS= read -r line; do
    printf '*'
    printf '%s\n' "$line" >> "$AGE_KEY_DIR/keys.txt"
  done
  stty echo
  trap - EXIT
  echo
  echo "    ($(wc -l < "$AGE_KEY_DIR/keys.txt") lines written)"
fi
chmod 600 "$AGE_KEY_DIR/keys.txt"

echo "==> [3/4] nixos-install"
nixos-install \
  --flake "$FLAKE_DIR#$FLAKE_HOST" \
  --no-root-passwd \
  --no-channel-copy

echo "==> [4/4] sbctl: creating Secure Boot keys"
# sbctl sandboxes itself with Landlock and only allows access to the canonical /etc/secureboot path
mkdir -p /mnt/etc/secureboot
nixos-enter --root /mnt -c "'$SBCTL_BIN' create-keys --database-path /etc/secureboot/keys"
nixos-enter --root /mnt -c "'$SBCTL_BIN' enroll-keys --database-path /etc/secureboot/keys --microsoft"

echo "==> Ready!"
