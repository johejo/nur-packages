{
  lib,
  buildGoModule,
  versionCheckHook,
  source,
  ...
}:

buildGoModule rec {
  inherit (source) pname version src;
  vendorHash = "sha256-qrmLEf4Tl3/L1w5+8DJY85Pl5De8zSUrNtbuSOIEL8U=";

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
