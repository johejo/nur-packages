{
  lib,
  buildGoModule,
  versionCheckHook,
  source,
  ...
}:

buildGoModule rec {
  inherit (source) pname version src;
  vendorHash = "sha256-eIQSdvAUSp92sCE8bzKFCHHx/IB33EcgOAn7F/OWyz0=";

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
  ];

  # Tests require a git repository context
  doCheck = false;

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;

  meta = {
    description = "Coding Agent Hooks Policy Framework Using CEL";
    mainProgram = "hocage";
    platforms = lib.platforms.unix;
  };
}
