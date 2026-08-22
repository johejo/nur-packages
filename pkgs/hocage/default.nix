{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
  versionCheckHook,
  ...
}:

buildGoModule rec {
  pname = "hocage";
  version = "0-unstable-2026-07-24";
  src = fetchFromGitHub {
    owner = "johejo";
    repo = "hocage";
    rev = "43daf740c8695c82509b0ef7a8695822496be5e2";
    hash = "sha256-arT6NJxHnkJM81QUmoBckOsiryEi+jZL6DGwzBmeg2M=";
  };
  vendorHash = "sha256-5gJAEAvQYHwbo7W9rWQJDXUY5o9NWlOhHSrIHzxyNzQ=";

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}+rev.${builtins.substring 0 12 src.rev}"
  ];

  # Tests require a git repository context
  doCheck = false;

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch=main" ]; };

  meta = {
    description = "Coding Agent Hooks Policy Framework Using CEL";
    homepage = "https://github.com/johejo/hocage";
    license = lib.licenses.asl20;
    mainProgram = "hocage";
    platforms = lib.platforms.unix;
  };
}
