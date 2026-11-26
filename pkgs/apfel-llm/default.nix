{
  lib,
  stdenvNoCC,
  fetchurl,
  nix-update-script,
  versionCheckHook,
}:

stdenvNoCC.mkDerivation rec {
  pname = "apfel-llm";
  version = "1.20.0";
  src = fetchurl {
    url = "https://github.com/Arthur-Ficial/apfel/releases/download/v${version}/apfel-${version}-arm64-macos.tar.gz";
    hash = "sha256-DNt+kVMqZnTH148ezx+VrhrjHIQxcvJ5dPRRYYFZjr4=";
  };

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

  passthru.updateScript = nix-update-script { };

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
