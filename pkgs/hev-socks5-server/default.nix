{
  lib,
  stdenv,
  fetchgit,
  nix-update-script,
  versionCheckHook,
  ...
}:

stdenv.mkDerivation rec {
  pname = "hev-socks5-server";
  version = "2.13.1";
  src = fetchgit {
    url = "https://github.com/heiher/hev-socks5-server.git";
    rev = version;
    fetchSubmodules = true;
    hash = "sha256-DvG2w5aKKes33Wj/b8SLjv5+C+k3Q2Ro37JgAyqMibw=";
  };

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

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Simple, lightweight SOCKS5 server";
    homepage = "https://github.com/heiher/hev-socks5-server";
    changelog = "https://github.com/heiher/hev-socks5-server/releases/tag/${version}";
    license = lib.licenses.mit;
    mainProgram = "hev-socks5-server";
    platforms = lib.platforms.unix;
  };
}
