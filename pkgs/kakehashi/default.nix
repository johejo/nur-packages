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
    description = "kakehashi - A Tree-sitter Language Server";
    homepage = "https://github.com/atusy/kakehashi";
    license = lib.licenses.mit;
    mainProgram = "kakehashi";
  };
}
