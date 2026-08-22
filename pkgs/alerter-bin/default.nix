{
  lib,
  stdenvNoCC,
  fetchurl,
  nix-update-script,
  unzip,
  versionCheckHook,
}:

stdenvNoCC.mkDerivation rec {
  pname = "alerter-bin";
  version = "26.5";
  src = fetchurl {
    url = "https://github.com/vjeantet/alerter/releases/download/v${version}/alerter-${version}.zip";
    hash = "sha256-EfY83cm7P4VU7Zt2JjKhIM+nvuBePAnWVzSCPgnSTxA=";
  };

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

  passthru.updateScript = nix-update-script { };

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
