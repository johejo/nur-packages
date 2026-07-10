{
  lib,
  stdenv,
  source,
  ...
}:

stdenv.mkDerivation rec {
  inherit (source) pname version src;

  sourceRoot = "source/src";

  installPhase = ''
    runHook preInstall
    install -Dm755 displayplacer $out/bin/displayplacer
    runHook postInstall
  '';

  meta = {
    description = "macOS command line utility to configure multi-display resolutions and arrangements. Essentially XRandR for macOS.";
    homepage = "https://github.com/jakehilborn/displayplacer";
    changelog = "https://github.com/jakehilborn/displayplacer/releases/tag/${version}";
    license = lib.licenses.mit;
    mainProgram = "displayplacer";
    platforms = lib.platforms.darwin;
  };
}
