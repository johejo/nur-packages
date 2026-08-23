{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
  versionCheckHook,
  ...
}:

buildGoModule rec {
  pname = "prometheus-nature-remo-exporter";
  version = "0-unstable-2026-08-23";

  src = fetchFromGitHub {
    owner = "johejo";
    repo = "prometheus-nature-remo-exporter";
    rev = "3a407f8d47f758ee925969167128f4ffd381e752";
    hash = "sha256-+hU77MKjC3n9lABgF7pWG6QlZR0JLtmHRo5XTmD0KfQ=";
  };

  subPackages = [ "cmd/nature-remo-exporter" ];
  vendorHash = "sha256-0KDzVmvon5AA1/zl6/f2IvSqEa1KS5YJ/lYCew7Ooa0=";

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
    description = "Prometheus exporter for Nature Remo devices and appliances";
    homepage = "https://github.com/johejo/prometheus-nature-remo-exporter";
    license = lib.licenses.mit;
    mainProgram = "nature-remo-exporter";
    platforms = lib.platforms.unix;
  };
}
