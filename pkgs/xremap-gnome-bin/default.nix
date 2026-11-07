{
  lib,
  stdenvNoCC,
  fetchurl,
  nix-update-script,
  unzip,
  versionCheckHook,
  ...
}:

let
  version = "0.15.17";
  sources = {
    x86_64-linux = fetchurl {
      url = "https://github.com/xremap/xremap/releases/download/v${version}/xremap-linux-x86_64-gnome.zip";
      hash = "sha256-/E0NGS0+hHkxAVG9NXr8VUCYdLJADEPWxyGC6g8vcC0=";
    };
    aarch64-linux = fetchurl {
      url = "https://github.com/xremap/xremap/releases/download/v${version}/xremap-linux-aarch64-gnome.zip";
      hash = "sha256-GP6TdMCMp2Ch/VliVupoPQlJ6Hc9wsawAw1IbIgjyJQ=";
    };
  };
in
stdenvNoCC.mkDerivation rec {
  pname = "xremap-gnome-bin";
  inherit version;
  src = sources.${stdenvNoCC.hostPlatform.system};

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

  passthru = {
    x86_64LinuxSrc = sources.x86_64-linux;
    aarch64LinuxSrc = sources.aarch64-linux;
    updateScript = nix-update-script {
      extraArgs = [
        "--system=${stdenvNoCC.hostPlatform.system}"
        "--custom-dep=x86_64LinuxSrc"
        "--custom-dep=aarch64LinuxSrc"
      ];
    };
  };

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
