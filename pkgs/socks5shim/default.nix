{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
  versionCheckHook,
  ...
}:

buildGoModule rec {
  pname = "socks5shim";
  version = "0-unstable-2026-07-17";

  src = fetchFromGitHub {
    owner = "johejo";
    repo = "socks5shim";
    rev = "65d1d643767d2bbc5a2ef9d9350031a2cf0d7289";
    hash = "sha256-FdCMVUFK5FHjryFynK89uDShyIdNb24J2HauVJimAMs=";
  };

  vendorHash = null;

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}+rev.${builtins.substring 0 12 src.rev}"
  ];

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;
  versionCheckProgramArg = "-version";

  passthru.updateScript = nix-update-script {
    extraArgs = [ "--version=branch=main" ];
  };

  meta = {
    description = "SOCKS5 upstream-fallback proxy shim";
    homepage = "https://github.com/johejo/socks5shim";
    license = lib.licenses.mit;
    mainProgram = "socks5shim";
    platforms = lib.platforms.unix;
  };
}
