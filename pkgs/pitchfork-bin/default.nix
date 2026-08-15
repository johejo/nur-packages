{
  lib,
  stdenv,
  source,
  autoPatchelfHook,
  libgcc,
  versionCheckHook,
  ...
}:

stdenv.mkDerivation rec {
  pname = "pitchfork-bin";
  inherit (source) version src;

  sourceRoot = ".";

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [ libgcc ];

  nativeInstallCheckInputs = [ versionCheckHook ];

  doInstallCheck = true;
  preVersionCheck = ''
    version="''${version#v}"
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 pitchfork $out/bin/pitchfork
    runHook postInstall
  '';

  meta = {
    description = "Daemons with DX";
    homepage = "https://pitchfork.jdx.dev";
    changelog = "https://github.com/jdx/pitchfork/releases/tag/${version}";
    license = lib.licenses.mit;
    mainProgram = "pitchfork";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
  };
}
