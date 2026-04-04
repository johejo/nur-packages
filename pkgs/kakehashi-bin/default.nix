{
  lib,
  stdenv,
  source,
  autoPatchelfHook,
  versionCheckHook,
  ...
}:

stdenv.mkDerivation rec {
  pname = "kakehashi-bin";
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
    install -Dm755 kakehashi $out/bin/kakehashi
    runHook postInstall
  '';

  meta = {
    description = "kakehashi - A Tree-sitter Language Server";
    homepage = "https://github.com/atusy/kakehashi";
    license = lib.licenses.mit;
    changelog = "https://github.com/atusy/kakehashi/releases/tag/${version}";
    mainProgram = "kakehashi";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
  };
}
