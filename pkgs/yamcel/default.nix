{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
  versionCheckHook,
  ...
}:

buildGoModule rec {
  pname = "yamcel";
  version = "0-unstable-2026-08-04";
  src = fetchFromGitHub {
    owner = "johejo";
    repo = "yamcel";
    rev = "1023a1a84527cd7686451fd344895203c31af746";
    hash = "sha256-iiwXt4Hoi9TH6/wV32/aUL2g2P20CsnaJufFHiCzC+E=";
  };
  subPackages = [ "cmd/yamcel" ];
  vendorHash = "sha256-GsviexzLlHHJY60iRkkhalTZ2GsbMMr7TJOPiOCxs58=";

  ldflags = [ "-X main.version=${version}+rev.${builtins.substring 0 12 src.rev}" ];

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;
  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch=main" ]; };

  meta = {
    description = "Type-check and format CEL expressions embedded in YAML";
    homepage = "https://github.com/johejo/yamcel";
    license = lib.licenses.mit;
    mainProgram = "yamcel";
    platforms = lib.platforms.unix;
  };
}
