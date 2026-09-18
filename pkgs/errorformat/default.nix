{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
  ...
}:

buildGoModule {
  pname = "errorformat";
  version = "0-unstable-2026-09-18";
  src = fetchFromGitHub {
    owner = "reviewdog";
    repo = "errorformat";
    rev = "3785ec08195ed6bba172e7e47a0770a91f1e6070";
    hash = "sha256-Yd9H3iSP/1y2Wl1YLlEA8ygYP5GzPA/zzhWsVq0ggW4=";
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
