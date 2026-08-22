{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
  versionCheckHook,
  ...
}:

buildGoModule rec {
  pname = "kubectl-schedsim";
  version = "0-unstable-2026-08-04";
  src = fetchFromGitHub {
    owner = "johejo";
    repo = "kubectl-schedsim";
    rev = "0eedb37cc65ba1a7247a1968419bfa30c99916af";
    hash = "sha256-JctSgAZtl0txU6IaUulcR1G0GwXw3LmIspAMANn3H8I=";
  };
  subPackages = [ "cmd/kubectl-schedsim" ];
  vendorHash = "sha256-NjUwNUaKeY13bOX6HBI8LCjUWeFRyUCX5shuBKs9IFI=";

  ldflags = [
    "-X github.com/johejo/kubectl-schedsim/pkg/version.Version=${version}+rev.${
      builtins.substring 0 12 src.rev
    }"
  ];

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;
  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch=main" ]; };

  meta = {
    description = "Simulate Kubernetes workload rollouts with the real scheduler framework";
    homepage = "https://github.com/johejo/kubectl-schedsim";
    license = lib.licenses.asl20;
    mainProgram = "kubectl-schedsim";
    platforms = lib.platforms.unix;
  };
}
