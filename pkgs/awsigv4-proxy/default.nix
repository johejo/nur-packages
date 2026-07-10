{
  lib,
  buildGoModule,
  versionCheckHook,
  source,
  ...
}:

buildGoModule rec {
  inherit (source) pname version src;
  subPackages = [ "." ];
  vendorHash = "sha256-1IUdxJLMtG3kv5Cs6K17Ip0FOBo75PeE1/apGMe7W8s=";

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
  ];

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;
  versionCheckProgramArg = "-version";

  meta = {
    description = "Alternative implementation of aws-sigv4-proxy";
    homepage = "https://github.com/johejo/awsigv4-proxy";
    license = lib.licenses.asl20;
    mainProgram = "awsigv4-proxy";
    platforms = lib.platforms.unix;
  };
}
