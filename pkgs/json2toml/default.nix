{
  lib,
  buildGoModule,
  source,
  ...
}:

buildGoModule {
  inherit (source) pname version src;
  vendorHash = "sha256-YgxwP/Y7VR9xlc9MZ1KGMpcLshzAhQM5apt0v0HVBO4=";

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${source.version}"
  ];

  meta = {
    description = "A tiny CLI that converts JSON to TOML";
    homepage = "https://github.com/johejo/json2toml";
    license = lib.licenses.mit;
    mainProgram = "json2toml";
    platforms = lib.platforms.unix;
  };
}
