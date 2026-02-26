{
  lib,
  stdenv,
  versionCheckHook,
  source,
  sourceMeta ? { },
  ...
}:

let
  sourceGit = sourceMeta.git;
  commit = sourceGit.commit;
  revId = if builtins.stringLength commit > 7 then builtins.substring 0 7 commit else commit;
in
stdenv.mkDerivation rec {
  inherit (source) pname version src;

  enableParallelBuilding = true;
  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;
  versionCheckProgramArg = "--version";
  preBuild = ''
    export REV_ID="${revId}"
  '';
  makeFlags = [
    "CC=cc"
    "STRIP=true"
  ];
  installFlags = [ "INSTDIR=$(out)" ];

  meta = {
    description = "Simple, lightweight SOCKS5 server";
    changelog = "https://github.com/heiher/hev-socks5-server/releases/tag/${version}";
    mainProgram = "hev-socks5-server";
    platforms = lib.platforms.unix;
  };
}
