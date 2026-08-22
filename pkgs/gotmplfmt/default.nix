{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
  ...
}:

buildGoModule rec {
  pname = "gotmplfmt";
  version = "0-unstable-2026-04-15";
  src = fetchFromGitHub {
    owner = "johejo";
    repo = "gotmplfmt";
    rev = "50f0bcb79afc1d7ee8e73ab996b0617e541dc0cd";
    hash = "sha256-z1AFVLo8c1EB4vibyL7bwDguTVQXOgPHvXF42YpW8lA=";
  };
  vendorHash = null;
  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch=main" ]; };

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}+rev.${builtins.substring 0 12 src.rev}"
  ];

  meta = {
    homepage = "https://github.com/johejo/gotmplfmt";
    license = lib.licenses.mit;
    mainProgram = "gotmplfmt";
  };
}
