{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
  versionCheckHook,
  ...
}:

buildGoModule rec {
  pname = "prometheus-tailscale-sd";
  version = "0-unstable-2026-08-16";

  src = fetchFromGitHub {
    owner = "johejo";
    repo = "prometheus-tailscale-sd";
    rev = "8c645b6e57589383a46a0b45aef37dd7300b810a";
    hash = "sha256-HBRgggMCoQvKZ6YbRMNwlDP4rUsb54OwY4tgtCWc6Tg=";
  };

  subPackages = [ "cmd/tailscale-sd" ];
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
    description = "Prometheus HTTP service discovery for Tailscale";
    homepage = "https://github.com/johejo/prometheus-tailscale-sd";
    license = lib.licenses.asl20;
    mainProgram = "tailscale-sd";
    platforms = lib.platforms.unix;
  };
}
