{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
  ...
}:

buildGoModule rec {
  pname = "asciigraph";
  version = "0.10.0";
  src = fetchFromGitHub {
    owner = "guptarohit";
    repo = "asciigraph";
    tag = "v${version}";
    hash = "sha256-VRF7wAiFQSL1PLmV0k2NjzuEKwprnS028FM0loTpmaI=";
  };
  subPackages = [ "cmd/asciigraph" ];
  vendorHash = null; # no external dependencies (empty go.sum)
  passthru.updateScript = nix-update-script { };

  ldflags = [
    "-s"
    "-w"
  ];

  meta = {
    description = "Lightweight ASCII line graphs ╭┈╯ for command-line apps";
    homepage = "https://github.com/guptarohit/asciigraph";
    license = lib.licenses.bsd3;
    mainProgram = "asciigraph";
    platforms = lib.platforms.unix;
  };
}
