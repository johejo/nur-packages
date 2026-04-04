{
  lib,
  stdenv,
  unzip,
  versionCheckHook,
  source,
}:

stdenv.mkDerivation rec {
  pname = "alerter-bin";
  inherit (source) version src;

  nativeBuildInputs = [
    unzip
    versionCheckHook
  ];

  unpackPhase = ''
    unzip $src
  '';

  doInstallCheck = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 alerter $out/bin/alerter
    runHook postInstall
  '';

  meta = {
    description = "Send User Alert Notification on MacOS from the command-line";
    homepage = "https://github.com/vjeantet/alerter";
    license = lib.licenses.mit;
    changelog = "https://github.com/vjeantet/alerter/releases/tag/v${version}";
    mainProgram = "alerter";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = lib.platforms.darwin;
  };
}
