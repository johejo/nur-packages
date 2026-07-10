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
    homepage = "https://github.com/awslabs/aws-sigv4-proxy";
    license = lib.licenses.asl20;
    mainProgram = "aws-sigv4-proxy";
    platforms = lib.platforms.unix;
  };
}
