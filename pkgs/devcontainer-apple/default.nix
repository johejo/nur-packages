{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
  versionCheckHook,
  ...
}:

buildGoModule rec {
  pname = "devcontainer-apple";
  version = "0-unstable-2026-09-25";
  src = fetchFromGitHub {
    owner = "johejo";
    repo = "devcontainer-apple";
    rev = "59daecb7acd71ba150c959cfa3707ef5b696b019";
    hash = "sha256-Ktt90aEsWrwXbVfRtjG4yhsRXd9PQ/AoBxQT3K6abVc=";
  };
  vendorHash = "sha256-7K17JaXFsjf163g5PXCb5ng2gYdotnZ2IDKk8KFjNj0=";
  subPackages = [ "cmd/devcontainer-apple" ];

  ldflags = [
    "-X github.com/johejo/devcontainer-apple/internal/cli.Version=${version}+rev.${
      builtins.substring 0 12 src.rev
    }"
  ];

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;
  versionCheckProgramArg = "--version";
  # This Docker CLI shim reports its Docker compatibility version.
  preVersionCheck = ''
    version=27.5.1
  '';
  postInstallCheck = ''
    "$out/bin/devcontainer-apple" --version | grep -F "+rev.${builtins.substring 0 12 src.rev}"
  '';

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch=main" ]; };

  meta = {
    description = "Docker CLI shim for running devcontainers on apple/container";
    homepage = "https://github.com/johejo/devcontainer-apple";
    license = lib.licenses.mit;
    mainProgram = "devcontainer-apple";
    platforms = [ "aarch64-darwin" ];
  };
}
