{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
  versionCheckHook,
  ...
}:

buildGoModule rec {
  pname = "tailctl";
  version = "0-unstable-2026-09-26";
  src = fetchFromGitHub {
    owner = "johejo";
    repo = "tailctl";
    rev = "776dd46fb464cfe5e500cb5d32776a20b3c9be89";
    hash = "sha256-zuxUhIYMnAEPL0x0EcZ3tcm5ziXyBckzr25Z7vxS2Ik=";
  };
  vendorHash = "sha256-nNwjOy1qtO5MdBYOsOoqPYZuIiOcTuUN2Z5ZkFKKq+s=";
  subPackages = [ "cmd/tailctl" ];
  ldflags = [ "-X main.version=${version}+rev.${builtins.substring 0 12 src.rev}" ];

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;
  versionCheckProgramArg = "--version";

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch=main" ]; };

  meta = {
    description = "Command-line client for the Tailscale API";
    homepage = "https://github.com/johejo/tailctl";
    license = lib.licenses.mit;
    mainProgram = "tailctl";
  };
}
