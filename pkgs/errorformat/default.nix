{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
  ...
}:

buildGoModule {
  pname = "errorformat";
  version = "0-unstable-2026-07-21";
  src = fetchFromGitHub {
    owner = "reviewdog";
    repo = "errorformat";
    rev = "13bff69235f30fd8b35c60151582584a7d81a50a";
    hash = "sha256-L3vdBzvsN+6iHFs1Jvpq4lZcN5KZKCFG0duo29UoKlM=";
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
