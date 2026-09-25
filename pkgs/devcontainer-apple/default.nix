{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
  versionCheckHook,
  ...
}:

buildGoModule {
  pname = "devcontainer-apple";
  version = "0-unstable-2026-09-25";
  src = fetchFromGitHub {
    owner = "johejo";
    repo = "devcontainer-apple";
    rev = "3a3900a45e2c8e1c6078789fcadf439530c83555";
    hash = "sha256-jdBR1h/6zAB7xuQm8ivVdeBTVxoeGSZw77d+YBuyFlk=";
  };
  vendorHash = "sha256-7K17JaXFsjf163g5PXCb5ng2gYdotnZ2IDKk8KFjNj0=";
  subPackages = [ "cmd/devcontainer-apple" ];

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;
  versionCheckProgramArg = "--version";
  # This Docker CLI shim reports its Docker compatibility version.
  preVersionCheck = ''
    version=27.5.1
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
