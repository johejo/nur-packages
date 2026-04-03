{
  lib,
  stdenv,
  source,
  autoPatchelfHook,
  versionCheckHook,
  ...
}:

stdenv.mkDerivation rec {
  pname = "octorus-bin";
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
    binary="$(find . -type f -name or -print -quit)"
    install -Dm755 "$binary" $out/bin/or
    ${lib.optionalString stdenv.isLinux ''
      autoPatchelf $out/bin/or
    ''}
    runHook postInstall
  '';

  meta = {
    description = "A TUI tool for GitHub PR review, designed for Helix editor users";
    homepage = "https://github.com/ushironoko/octorus";
    license = lib.licenses.mit;
    changelog = "https://github.com/ushironoko/octorus/releases/tag/v${version}";
    mainProgram = "or";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
  };
}
