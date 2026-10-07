{
  lib,
  stdenvNoCC,
  fetchurl,
  nix-update-script,
  versionCheckHook,
  ...
}:

let
  version = "0.1319.920600001";
  sources = {
    aarch64-darwin = fetchurl {
      url = "https://github.com/boldsoftware/shelley/releases/download/v${version}/shelley_darwin_arm64";
      hash = "sha256-m7e4e3N8KYi45QIE69FrpAchqA/a+cSf6n5FAKVXeoE=";
    };
    x86_64-linux = fetchurl {
      url = "https://github.com/boldsoftware/shelley/releases/download/v${version}/shelley_linux_amd64";
      hash = "sha256-f+AxKabC+JFwGan22EbcFyAevwSkqT0Io+9xcE+OTk8=";
    };
    aarch64-linux = fetchurl {
      url = "https://github.com/boldsoftware/shelley/releases/download/v${version}/shelley_linux_arm64";
      hash = "sha256-kUpNjsmOly/g1a1ANJ4ZREWTWSXjDZHaCHSmGD5AMJ4=";
    };
  };
in
stdenvNoCC.mkDerivation rec {
  pname = "shelley-bin";
  inherit version;
  src = sources.${stdenvNoCC.hostPlatform.system};

  dontUnpack = true;

  nativeInstallCheckInputs = [ versionCheckHook ];

  doInstallCheck = true;
  versionCheckProgramArg = "version";
  preVersionCheck = ''
    version="''${version#v}"
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/shelley
    runHook postInstall
  '';

  passthru = {
    aarch64DarwinSrc = sources.aarch64-darwin;
    x86_64LinuxSrc = sources.x86_64-linux;
    aarch64LinuxSrc = sources.aarch64-linux;
    updateScript = nix-update-script {
      extraArgs = [
        "--version-regex=v(.*)"
        "--custom-dep=aarch64DarwinSrc"
        "--custom-dep=x86_64LinuxSrc"
        "--custom-dep=aarch64LinuxSrc"
      ];
    };
  };

  meta = {
    description = "Mobile-friendly, web-based, multi-modal coding agent";
    homepage = "https://github.com/boldsoftware/shelley";
    changelog = "https://github.com/boldsoftware/shelley/releases/tag/v${version}";
    license = lib.licenses.asl20;
    mainProgram = "shelley";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
  };
}
