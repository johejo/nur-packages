{
  lib,
  buildGoModule,
  versionCheckHook,
  source,
  ...
}:

buildGoModule {
  inherit (source) pname version src;
  subPackages = [ "cmd/yamcel" ];
  vendorHash = "sha256-GsviexzLlHHJY60iRkkhalTZ2GsbMMr7TJOPiOCxs58=";

  ldflags = [ "-X main.version=${source.version}" ];

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;

  meta = {
    description = "Type-check and format CEL expressions embedded in YAML";
    homepage = "https://github.com/johejo/yamcel";
    license = lib.licenses.mit;
    mainProgram = "yamcel";
    platforms = lib.platforms.unix;
  };
}
