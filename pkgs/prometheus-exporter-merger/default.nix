{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
  versionCheckHook,
  ...
}:

buildGoModule rec {
  pname = "prometheus-exporter-merger";
  version = "0-unstable-2026-09-11";

  src = fetchFromGitHub {
    owner = "johejo";
    repo = "prometheus-exporter-merger";
    rev = "0adae052b5e4aeef3b877c59693dc8542f842b6c";
    hash = "sha256-KhI0iXw8zw2vbLHv6YKjo3dT9JOunVhf7hWOSkuB5rY=";
  };

  subPackages = [ "cmd/exporter-merger" ];
  vendorHash = "sha256-wkcj/losx4yBYv0wye/q7pQlL2LEeiW9/2sM+iSDngk=";

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}+rev.${builtins.substring 0 12 src.rev}"
  ];

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;
  versionCheckProgramArg = "-version";

  passthru.updateScript = nix-update-script {
    extraArgs = [ "--version=branch=main" ];
  };

  meta = {
    description = "Proxy that merges multiple Prometheus exporters into a single exporter";
    homepage = "https://github.com/johejo/prometheus-exporter-merger";
    license = lib.licenses.asl20;
    mainProgram = "exporter-merger";
    platforms = lib.platforms.unix;
  };
}
