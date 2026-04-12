{
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
    mainProgram = "gotmplfmt";
  };
}
