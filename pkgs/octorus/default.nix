{
  lib,
  rustPlatform,
  git,
  versionCheckHook,
  source,
  ...
}:

rustPlatform.buildRustPackage {
  inherit (source) pname version src;

  cargoLock = source.cargoLock."Cargo.lock";

  doCheck = true;
  nativeCheckInputs = [ git ];
  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;
  preVersionCheck = ''
    version="''${version#v}"
  '';

  meta = {
    license = lib.licenses.mit;
    mainProgram = "or";
  };
}
