{
  lib,
  buildGoModule,
  versionCheckHook,
  source,
  ...
}:

buildGoModule rec {
  inherit (source) pname version src;
  vendorHash = null;

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
  ];

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;
  versionCheckProgramArg = "-version";

  meta = {
    description = "SOCKS5 upstream-fallback proxy shim";
    license = lib.licenses.mit;
    mainProgram = "socks5shim";
    platforms = lib.platforms.unix;
  };
}
