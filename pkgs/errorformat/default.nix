{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
  ...
}:

buildGoModule {
  pname = "errorformat";
  version = "0-unstable-2026-11-11";
  src = fetchFromGitHub {
    owner = "reviewdog";
    repo = "errorformat";
    rev = "96826ccdd0bd4b1f25d882aecf96ef292cd84e4e";
    hash = "sha256-Arwc5U6KTPZIhQEhwP5hH3HJ+0rJrwQY7+eJ1QAZQHA=";
  };
  vendorHash = "sha256-gb5J5L41Rz96wsnpb/PjtQt8ob038KzjgxLXCnytyRc=";
  subPackages = [ "cmd/errorformat" ];
  ldflags = [
    "-s"
    "-w"
  ];
  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch=master" ]; };
  meta = {
    description = "Vim's quickfix errorformat implementation in Go";
    homepage = "https://github.com/reviewdog/errorformat";
    license = lib.licenses.mit;
    mainProgram = "errorformat";
  };
}
