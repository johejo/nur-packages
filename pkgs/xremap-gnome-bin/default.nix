{
  lib,
  stdenv,
  unzip,
  versionCheckHook,
  source,
  ...
}:

stdenv.mkDerivation rec {
  pname = "xremap-gnome-bin";
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
    install -Dm755 xremap $out/bin/xremap
    runHook postInstall
  '';

  meta = {
    description = "Key remapper for X11 and Wayland (Gnome support)";
    homepage = "https://github.com/xremap/xremap";
    license = lib.licenses.mit;
    changelog = "https://github.com/xremap/xremap/blob/v${version}/CHANGELOG.md";
    mainProgram = "xremap";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}
