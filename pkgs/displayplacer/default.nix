{
  lib,
  stdenv,
  fetchFromGitHub,
  nix-update-script,
  ...
}:

stdenv.mkDerivation rec {
  pname = "displayplacer";
  version = "1.4.0";
  src = fetchFromGitHub {
    owner = "jakehilborn";
    repo = "displayplacer";
    tag = "v${version}";
    hash = "sha256-BYq8lrS8yE9ARCdAvZxiuC/2vRv6uha++WwKfM37gC0=";
  };

  sourceRoot = "source/src";

  installPhase = ''
    runHook preInstall
    install -Dm755 displayplacer $out/bin/displayplacer
    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "macOS command line utility to configure multi-display resolutions and arrangements. Essentially XRandR for macOS.";
    homepage = "https://github.com/jakehilborn/displayplacer";
    changelog = "https://github.com/jakehilborn/displayplacer/releases/tag/v${version}";
    license = lib.licenses.mit;
    mainProgram = "displayplacer";
    platforms = lib.platforms.darwin;
  };
}
