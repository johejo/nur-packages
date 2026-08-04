{
  lib,
  buildGoModule,
  versionCheckHook,
  source,
  ...
}:

buildGoModule {
  inherit (source) pname version src;
  subPackages = [ "cmd/kubectl-schedsim" ];
  vendorHash = "sha256-NjUwNUaKeY13bOX6HBI8LCjUWeFRyUCX5shuBKs9IFI=";

  ldflags = [
    "-X github.com/johejo/kubectl-schedsim/pkg/version.Version=${source.version}"
  ];

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;

  meta = {
    description = "Simulate Kubernetes workload rollouts with the real scheduler framework";
    homepage = "https://github.com/johejo/kubectl-schedsim";
    license = lib.licenses.asl20;
    mainProgram = "kubectl-schedsim";
    platforms = lib.platforms.unix;
  };
}
