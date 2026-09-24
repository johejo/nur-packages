{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
  ...
}:

buildGoModule {
  pname = "gfterm";
  version = "0-unstable-2026-08-27";
  src = fetchFromGitHub {
    owner = "johejo";
    repo = "gfterm";
    rev = "951542d7e77fb44e1893caa82cb49f81807d1a8f";
    hash = "sha256-6OPGaD8QMl5JZ4gCraKoB7oXW0pjaGfWlwsbhJxZA1c=";
  };
  vendorHash = "sha256-pU0viriqbDFtjPS6Ll+1o2fo8aNdJPgi5k9A2vxpTL8=";
  subPackages = [ "cmd/gfterm" ];

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch=main" ]; };

  meta = {
    description = "Terminal dashboard viewer for Grafana";
    homepage = "https://github.com/johejo/gfterm";
    license = lib.licenses.asl20;
    mainProgram = "gfterm";
  };
}
