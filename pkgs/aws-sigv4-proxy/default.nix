{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
  ...
}:

buildGoModule rec {
  pname = "aws-sigv4-proxy";
  version = "1.12";
  src = fetchFromGitHub {
    owner = "awslabs";
    repo = "aws-sigv4-proxy";
    tag = "v${version}";
    hash = "sha256-U0Jxe52bmV+QaS+mKNdW+VzzCtulRL1ZanbWxp4oqcs=";
  };
  subPackages = [ "cmd/aws-sigv4-proxy" ];
  vendorHash = null; # module is vendored upstream
  passthru.updateScript = nix-update-script { };

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
