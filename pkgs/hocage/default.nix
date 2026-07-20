{
  lib,
  buildGoModule,
  versionCheckHook,
  source,
  ...
}:

buildGoModule rec {
  inherit (source) pname version src;
  vendorHash = "sha256-5gJAEAvQYHwbo7W9rWQJDXUY5o9NWlOhHSrIHzxyNzQ=";

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
    homepage = "https://github.com/johejo/hocage";
    license = lib.licenses.asl20;
    mainProgram = "hocage";
    platforms = lib.platforms.unix;
  };
}
