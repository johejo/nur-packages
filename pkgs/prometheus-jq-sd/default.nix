{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
  versionCheckHook,
  ...
}:

buildGoModule rec {
  pname = "prometheus-jq-sd";
  version = "0-unstable-2026-08-16";

  src = fetchFromGitHub {
    owner = "johejo";
    repo = "prometheus-jq-sd";
    rev = "6c866ba28ed9a76ba4c4be06ab2b1e4f4165629c";
    hash = "sha256-v4VgvbQTB5rXOjZCoNR1UaJKmQE7DjCXg7w+lsamt5s=";
  };

  subPackages = [ "cmd/jq-sd" ];
  vendorHash = "sha256-O1oVCx2+JBYM3R9YbJdbRQdxGxgCq/Aoks47tgw610k=";

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}+rev.${builtins.substring 0 12 src.rev}"
  ];

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;
  versionCheckProgramArg = "--version";

  passthru.updateScript = nix-update-script {
    extraArgs = [ "--version=branch=main" ];
  };

  meta = {
    description = "Generic Prometheus HTTP service discovery powered by jq";
    homepage = "https://github.com/johejo/prometheus-jq-sd";
    license = lib.licenses.asl20;
    mainProgram = "jq-sd";
    platforms = lib.platforms.unix;
  };
}
