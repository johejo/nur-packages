{
  lib,
  stdenv,
  source,
  autoPatchelfHook,
  libgcc,
  ...
}:

stdenv.mkDerivation rec {
  pname = "cclens-bin";
  inherit (source) version src;

  sourceRoot = ".";

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [ libgcc ];

  doInstallCheck = true;

  installCheckPhase = ''
    runHook preInstallCheck
    $out/bin/cclens --help > /dev/null
    runHook postInstallCheck
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 cclens $out/bin/cclens
    runHook postInstall
  '';

  meta = {
    description = "Lens onto your Claude Code usage";
    homepage = "https://github.com/lambdalisue/cclens";
    changelog = "https://github.com/lambdalisue/cclens/releases/tag/${version}";
    mainProgram = "cclens";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
  };
}
