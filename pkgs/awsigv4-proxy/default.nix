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
    mainProgram = "awsigv4-proxy";
    platforms = lib.platforms.unix;
  };
}
