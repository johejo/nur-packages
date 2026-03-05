{
  rustPlatform,
  versionCheckHook,
  source,
  ...
}:

rustPlatform.buildRustPackage {
  inherit (source) pname version src;

  cargoLock = source.cargoLock."Cargo.lock";

  doCheck = false;
  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;
  preVersionCheck = ''
    version="''${version#v}"
  '';

  meta = {
    mainProgram = "gws";
  };
}
