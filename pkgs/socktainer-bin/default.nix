{
  lib,
  stdenvNoCC,
  fetchurl,
  nix-update-script,
  versionCheckHook,
}:

stdenvNoCC.mkDerivation rec {
  pname = "socktainer-bin";
  version = "1.2.1";
  src = fetchurl {
    url = "https://github.com/socktainer/socktainer/releases/download/v${version}/socktainer";
    hash = "sha256-MwSmK8HClALcOaRaHcdAmJBMneqCZ/etl//xrwIvrAs=";
  };

  dontUnpack = true;

  nativeInstallCheckInputs = [ versionCheckHook ];

  doInstallCheck = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/socktainer
    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Docker-compatible REST API on top of Apple container";
    homepage = "https://github.com/socktainer/socktainer";
    license = lib.licenses.asl20;
    changelog = "https://github.com/socktainer/socktainer/releases/tag/v${version}";
    mainProgram = "socktainer";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "aarch64-darwin" ];
  };
}
