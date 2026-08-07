{
  lib,
  stdenv,
  versionCheckHook,
  source,
  ...
}:

stdenv.mkDerivation rec {
  pname = "zot-bin";
  inherit (source) version src;

  dontUnpack = true;

  nativeInstallCheckInputs = [ versionCheckHook ];

  doInstallCheck = true;

  preVersionCheck = ''
    version="''${version#v}"
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/zot
    runHook postInstall
  '';

  meta = {
    description = "Production-ready vendor-neutral OCI-native container image registry";
    homepage = "https://zotregistry.dev";
    changelog = "https://github.com/project-zot/zot/releases/tag/${version}";
    license = lib.licenses.asl20;
    mainProgram = "zot";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
  };
}
