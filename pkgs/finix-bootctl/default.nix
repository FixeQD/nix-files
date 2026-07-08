{ lib, rustPlatform }:

rustPlatform.buildRustPackage {
  pname = "finix-bootctl";
  version = "0.1.0";

  src = lib.cleanSource ./.;

  cargoLock.lockFile = ./Cargo.lock;
  doCheck = false;

  meta = {
    description = "Manage Finix EFISTUB boot entries via efivar/gpt instead of efibootmgr";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
    mainProgram = "finix-bootctl";
  };
}