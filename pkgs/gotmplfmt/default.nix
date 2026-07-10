{
  lib,
  buildGoModule,
  source,
  ...
}:

buildGoModule {
  inherit (source) pname version src;
  vendorHash = null;

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${source.version}"
  ];

  meta = {
    homepage = "https://github.com/johejo/gotmplfmt";
    license = lib.licenses.mit;
    mainProgram = "gotmplfmt";
  };
}
