{
  lib,
  buildGoModule,
  source,
  ...
}:

buildGoModule {
  inherit (source) pname version src;
  subPackages = [ "." ];
  vendorHash = null;

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${source.version}"
  ];

  meta = {
    description = "A small CLI tool for rendering text/template";
    homepage = "https://github.com/johejo/gotmpl";
    license = lib.licenses.mit;
    mainProgram = "gotmpl";
  };
}
