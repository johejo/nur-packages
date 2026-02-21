{
  lib,
  rustPlatform,
  source,
  ...
}:

rustPlatform.buildRustPackage {
  inherit (source) pname version src;

  cargoLock = source.cargoLock."Cargo.lock";

  doCheck = false;

  meta = {
    license = lib.licenses.mit;
    mainProgram = "kakehashi";
  };
}
