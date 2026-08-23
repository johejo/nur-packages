{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
  versionCheckHook,
  ...
}:

buildGoModule rec {
  pname = "prometheus-jq-exporter";
  version = "0-unstable-2026-08-16";

  src = fetchFromGitHub {
    owner = "johejo";
    repo = "prometheus-jq-exporter";
    rev = "bad902d88a69bcf294a36aa89c43e09c6797d471";
    hash = "sha256-a1+5s6WZp6vSu2MPryzFKrexVyPaqSdgOicPZclGm60=";
  };

  subPackages = [ "cmd/jq-exporter" ];
  vendorHash = "sha256-WcfQk/LHyFzzE84h7eYiAfAcuXMDfeJjM5NZYbUjlUw=";

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
    description = "Prometheus exporter for JSON endpoints using jq expressions";
    homepage = "https://github.com/johejo/prometheus-jq-exporter";
    license = lib.licenses.bsd3;
    mainProgram = "jq-exporter";
    platforms = lib.platforms.unix;
  };
}
