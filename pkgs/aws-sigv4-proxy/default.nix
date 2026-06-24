{
  lib,
  buildGoModule,
  source,
  ...
}:

buildGoModule {
  inherit (source) pname version src;
  subPackages = [ "cmd/aws-sigv4-proxy" ];
  vendorHash = null; # module is vendored upstream

  ldflags = [
    "-s"
    "-w"
  ];

  meta = {
    description = "Proxy that signs and forwards HTTP requests using AWS Signature Version 4";
    mainProgram = "aws-sigv4-proxy";
    platforms = lib.platforms.unix;
  };
}
