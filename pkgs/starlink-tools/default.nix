{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
  versionCheckHook,
  ...
}:

buildGoModule rec {
  pname = "starlink-tools";
  version = "0-unstable-2026-09-12";

  src = fetchFromGitHub {
    owner = "johejo";
    repo = "starlink-tools";
    rev = "6609fb33b721efedc7d2f255dbcb1dc541e38bd0";
    hash = "sha256-ugurDANSdeisA5QdvPo1XXFISkfgkJbeUHop0cFZCDI=";
  };

  subPackages = [
    "cmd/starlink-exporter"
    "cmd/starlinkctl"
  ];
  vendorHash = "sha256-H0NUyT3SqcIFAlmy8uWzJZqOPnEPFkgb0eYbR78Qdds=";

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}+rev.${builtins.substring 0 12 src.rev}"
  ];

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;
  versionCheckProgram = "${placeholder "out"}/bin/starlink-exporter";
  versionCheckProgramArg = "-version";

  passthru.updateScript = nix-update-script {
    extraArgs = [ "--version=branch=main" ];
  };

  meta = {
    description = "Command-line tools for interacting with a Starlink dish";
    homepage = "https://github.com/johejo/starlink-tools";
    license = lib.licenses.asl20;
    mainProgram = "starlinkctl";
    platforms = lib.platforms.unix;
  };
}
