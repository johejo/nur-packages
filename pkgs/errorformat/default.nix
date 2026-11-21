{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
  ...
}:

buildGoModule {
  pname = "errorformat";
  version = "0-unstable-2026-11-17";
  src = fetchFromGitHub {
    owner = "reviewdog";
    repo = "errorformat";
    rev = "76245124aebdf752403fb01ba174403cf43dae33";
    hash = "sha256-sdvtXwkfSM8vPDmNOh2a69TjwxJCK4gvcjQOAYYnZuM=";
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
