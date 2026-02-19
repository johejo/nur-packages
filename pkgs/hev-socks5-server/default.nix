{
  lib,
  stdenv,
  git,
  versionCheckHook,
  source,
  ...
}:

stdenv.mkDerivation rec {
  inherit (source) pname version src;

  enableParallelBuilding = true;
  nativeBuildInputs = [ git ];
  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;
  versionCheckProgramArg = "--version";
  preBuild = ''
    export REV_ID="$(git rev-parse --short HEAD)"
  '';
  makeFlags = [
    "CC=cc"
    "STRIP=true"
  ];
  installFlags = [ "INSTDIR=$(out)" ];

  meta = {
    description = "Simple, lightweight SOCKS5 server";
    homepage = "https://github.com/heiher/hev-socks5-server";
    license = lib.licenses.mit;
    changelog = "https://github.com/heiher/hev-socks5-server/releases/tag/${version}";
    mainProgram = "hev-socks5-server";
    platforms = lib.platforms.unix;
  };
}
