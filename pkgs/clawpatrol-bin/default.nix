{
  lib,
  stdenv,
  versionCheckHook,
  source,
  ...
}:

stdenv.mkDerivation rec {
  pname = "clawpatrol-bin";
  inherit (source) version src;

  dontUnpack = true;

  nativeInstallCheckInputs = [ versionCheckHook ];

  doInstallCheck = true;

  preVersionCheck = ''
    version="''${version#v}"
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/clawpatrol
    runHook postInstall
  '';

  meta = {
    description = "Security firewall for agents";
    homepage = "https://clawpatrol.dev";
    changelog = "https://github.com/denoland/clawpatrol/releases/tag/${version}";
    license = lib.licenses.mit;
    mainProgram = "clawpatrol";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
  };
}
