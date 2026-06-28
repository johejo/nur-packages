{
  lib,
  buildGoModule,
  source,
  ...
}:

buildGoModule {
  inherit (source) pname version src;
  subPackages = [ "cmd/asciigraph" ];
  vendorHash = null; # no external dependencies (empty go.sum)

  ldflags = [
    "-s"
    "-w"
  ];

  meta = {
    description = "Lightweight ASCII line graphs ╭┈╯ for command-line apps";
    homepage = "https://github.com/guptarohit/asciigraph";
    license = lib.licenses.bsd3;
    mainProgram = "asciigraph";
    platforms = lib.platforms.unix;
  };
}
