{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
  ...
}:

buildGoModule rec {
  pname = "json2toml";
  version = "0-unstable-2026-06-13";
  src = fetchFromGitHub {
    owner = "johejo";
    repo = "json2toml";
    rev = "4f4070151e5e2d18627631070074b05996b61458";
    hash = "sha256-ABup53MZL/w5L6G/WEOc9QckKDAOkfoGwOhrja7Woec=";
  };
  vendorHash = "sha256-YgxwP/Y7VR9xlc9MZ1KGMpcLshzAhQM5apt0v0HVBO4=";

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}+rev.${builtins.substring 0 12 src.rev}"
  ];

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch=main" ]; };

  meta = {
    description = "A tiny CLI that converts JSON to TOML";
    homepage = "https://github.com/johejo/json2toml";
    license = lib.licenses.mit;
    mainProgram = "json2toml";
    platforms = lib.platforms.unix;
  };
}
