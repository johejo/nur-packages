{
  rustPlatform,
  source,
  ...
}:

rustPlatform.buildRustPackage {
  inherit (source) pname version src;

  cargoLock = source.cargoLock."Cargo.lock";

  doCheck = false;

  meta = {
    mainProgram = "kakehashi";
  };
}
