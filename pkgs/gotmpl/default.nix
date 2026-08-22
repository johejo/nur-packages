{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
  ...
}:

buildGoModule rec {
  pname = "gotmpl";
  version = "0-unstable-2026-06-30";
  src = fetchFromGitHub {
    owner = "johejo";
    repo = "gotmpl";
    rev = "c4f96c3f57bd6ce36c581d31b5b4bb82877f4be7";
    hash = "sha256-2rFZZYN+wzf0LKWSx6hbYDG1mtx07o1AHIkpAYsF1Uo=";
  };
  subPackages = [ "." ];
  vendorHash = null;
  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch=main" ]; };

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}+rev.${builtins.substring 0 12 src.rev}"
  ];

  meta = {
    description = "A small CLI tool for rendering text/template";
    homepage = "https://github.com/johejo/gotmpl";
    license = lib.licenses.mit;
    mainProgram = "gotmpl";
  };
}
