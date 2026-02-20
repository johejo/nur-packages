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
    description = "A TUI tool for GitHub PR review, designed for Helix editor users";
    homepage = "https://github.com/ushironoko/octorus";
    license = lib.licenses.mit;
    mainProgram = "or";
  };
}
