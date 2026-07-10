{
  lib,
  stdenv,
  versionCheckHook,
  source,
  ...
}:

stdenv.mkDerivation rec {
  inherit (source) pname version src;

  enableParallelBuilding = true;
  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;
  versionCheckProgramArg = "--version";
  preBuild = ''
    export REV_ID="${src.rev}"
  '';
  makeFlags = [
    "CC=cc"
    "STRIP=true"
  ];
  installFlags = [ "INSTDIR=$(out)" ];

  meta = {
    description = "Simple, lightweight SOCKS5 server";
    homepage = "https://github.com/heiher/hev-socks5-server";
    changelog = "https://github.com/heiher/hev-socks5-server/releases/tag/${version}";
    license = lib.licenses.mit;
    mainProgram = "hev-socks5-server";
    platforms = lib.platforms.unix;
  };
}
