{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
  ...
}:

buildGoModule {
  pname = "devcontainer-apple";
  version = "0-unstable-2026-09-24";
  src = fetchFromGitHub {
    owner = "johejo";
    repo = "devcontainer-apple";
    rev = "9ae569e34a85cd83c7b51b3759f95fe351916b49";
    hash = "sha256-Hugaa/lOdoebj6k/hQW1QYQtp+J2ZUtlHWVc7YS0lZQ=";
  };
  vendorHash = "sha256-7K17JaXFsjf163g5PXCb5ng2gYdotnZ2IDKk8KFjNj0=";
  subPackages = [ "cmd/devcontainer-apple" ];

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch=main" ]; };

  meta = {
    description = "Docker CLI shim for running devcontainers on apple/container";
    homepage = "https://github.com/johejo/devcontainer-apple";
    license = lib.licenses.mit;
    mainProgram = "devcontainer-apple";
    platforms = [ "aarch64-darwin" ];
  };
}
