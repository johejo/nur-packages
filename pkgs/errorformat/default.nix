{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
  ...
}:

buildGoModule {
  pname = "errorformat";
  version = "0-unstable-2026-09-15";
  src = fetchFromGitHub {
    owner = "reviewdog";
    repo = "errorformat";
    rev = "8f381a90ad6c599828f1b9266c6c810fbbb5ace8";
    hash = "sha256-DHoQ/AQBP72+zdr9qo9JuC3WZMP9G0FeD15DULuN86U=";
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
