{
  lib,
  stdenvNoCC,
  fetchurl,
  nix-update-script,
  versionCheckHook,
  ...
}:

let
  version = "0.5.15";
  sources = {
    aarch64-darwin = fetchurl {
      url = "https://github.com/denoland/clawpatrol/releases/download/v${version}/clawpatrol-darwin-arm64";
      hash = "sha256-ewVCkMP5vqYO0Kx6Jn5RnSU5ky9eHx89tKNZCBywrIg=";
    };
    x86_64-linux = fetchurl {
      url = "https://github.com/denoland/clawpatrol/releases/download/v${version}/clawpatrol-linux-amd64";
      hash = "sha256-3GisP2thD1GARQKp++dTUCSY4+gr44HRIN8DnyYqVGw=";
    };
    aarch64-linux = fetchurl {
      url = "https://github.com/denoland/clawpatrol/releases/download/v${version}/clawpatrol-linux-arm64";
      hash = "sha256-NMo/JNk5PVaHSZU0r7rtRW8IXYDK1xNzLNJRZBODhms=";
    };
  };
in
stdenvNoCC.mkDerivation rec {
  pname = "clawpatrol-bin";
  inherit version;
  src = sources.${stdenvNoCC.hostPlatform.system};

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

  passthru = {
    aarch64DarwinSrc = sources.aarch64-darwin;
    x86_64LinuxSrc = sources.x86_64-linux;
    aarch64LinuxSrc = sources.aarch64-linux;
    updateScript = nix-update-script {
      extraArgs = [
        "--custom-dep=aarch64DarwinSrc"
        "--custom-dep=x86_64LinuxSrc"
        "--custom-dep=aarch64LinuxSrc"
      ];
    };
  };

  meta = {
    description = "Security firewall for agents";
    homepage = "https://clawpatrol.dev";
    changelog = "https://github.com/denoland/clawpatrol/releases/tag/v${version}";
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
