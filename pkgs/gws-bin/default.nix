{
  lib,
  stdenv,
  source,
  autoPatchelfHook,
  versionCheckHook,
  ...
}:

stdenv.mkDerivation rec {
  pname = "gws-bin";
  inherit (source) version src;

  sourceRoot = ".";

  nativeBuildInputs = [ versionCheckHook ] ++ lib.optionals stdenv.isLinux [ autoPatchelfHook ];

  buildInputs = [ stdenv.cc.cc.lib ];

  doInstallCheck = true;
  preVersionCheck = ''
    version="''${version#v}"
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    install -Dm755 gws $out/bin/gws
    ${lib.optionalString stdenv.isLinux ''
      autoPatchelf $out/bin/gws
    ''}
    runHook postInstall
  '';

  meta = {
    description = "Google Workspace CLI - dynamic command surface from Discovery Service";
    homepage = "https://github.com/googleworkspace/cli";
    license = lib.licenses.asl20;
    changelog = "https://github.com/googleworkspace/cli/releases/tag/${version}";
    mainProgram = "gws";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
  };
}
