{
  lib,
  stdenv,
  versionCheckHook,
  source,
  sourceMeta ? { },
  ...
}:

stdenv.mkDerivation rec {
  inherit (source) pname version src;
  sourceGit = sourceMeta.git or { };
  commit = sourceGit.commit or sourceGit.ref or source.rev;
  revId = if builtins.stringLength commit > 7 then builtins.substring 0 7 commit else commit;

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
