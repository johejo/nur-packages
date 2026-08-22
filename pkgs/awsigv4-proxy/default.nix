{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
  versionCheckHook,
  ...
}:

buildGoModule rec {
  pname = "awsigv4-proxy";
  version = "0-unstable-2026-07-10";
  src = fetchFromGitHub {
    owner = "johejo";
    repo = "awsigv4-proxy";
    rev = "10a42826710542f17d0985ce2c18fa8133aba438";
    hash = "sha256-bL6sB3M5edh5AAJe0saiohDcqHzH7jrN7EjqeMYBV/s=";
  };
  subPackages = [ "." ];
  vendorHash = "sha256-1IUdxJLMtG3kv5Cs6K17Ip0FOBo75PeE1/apGMe7W8s=";

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}+rev.${builtins.substring 0 12 src.rev}"
  ];

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;
  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch=main" ]; };
  versionCheckProgramArg = "-version";

  meta = {
    description = "Alternative implementation of aws-sigv4-proxy";
    homepage = "https://github.com/johejo/awsigv4-proxy";
    license = lib.licenses.asl20;
    mainProgram = "awsigv4-proxy";
    platforms = lib.platforms.unix;
  };
}
