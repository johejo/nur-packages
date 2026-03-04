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
    changelog = "https://github.com/jakehilborn/displayplacer/releases/tag/${version}";
    mainProgram = "displayplacer";
    platforms = lib.platforms.darwin;
  };
}
