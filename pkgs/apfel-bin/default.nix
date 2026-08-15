{
  lib,
  stdenvNoCC,
  versionCheckHook,
  source,
}:

stdenvNoCC.mkDerivation rec {
  pname = "apfel-bin";
  inherit (source) version src;

  sourceRoot = ".";

  nativeBuildInputs = [ versionCheckHook ];

  doInstallCheck = true;
  preVersionCheck = ''
    version="v${version}"
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 apfel $out/bin/apfel
    runHook postInstall
  '';

  meta = {
    description = "On-device Apple FoundationModels CLI and OpenAI-compatible server";
    homepage = "https://github.com/Arthur-Ficial/apfel";
    license = lib.licenses.mit;
    changelog = "https://github.com/Arthur-Ficial/apfel/releases/tag/v${version}";
    mainProgram = "apfel";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "aarch64-darwin" ];
  };
}
