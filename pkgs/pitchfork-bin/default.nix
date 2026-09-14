{
  lib,
  stdenvNoCC,
  fetchurl,
  nix-update-script,
  autoPatchelfHook,
  libgcc,
  versionCheckHook,
  ...
}:

let
  version = "2.25.0";
  sources = {
    aarch64-darwin = fetchurl {
      url = "https://github.com/jdx/pitchfork/releases/download/v${version}/pitchfork-aarch64-apple-darwin.tar.gz";
      hash = "sha256-wkQ5M2eshIFPek5EtqTN+C1V2PtklNGNXHy8vzaMank=";
    };
    x86_64-linux = fetchurl {
      url = "https://github.com/jdx/pitchfork/releases/download/v${version}/pitchfork-x86_64-unknown-linux-gnu.tar.gz";
      hash = "sha256-fOaBWCAUMNP1u1tslneOP2OKv6IJFHcTsDkvVL+t70o=";
    };
    aarch64-linux = fetchurl {
      url = "https://github.com/jdx/pitchfork/releases/download/v${version}/pitchfork-aarch64-unknown-linux-gnu.tar.gz";
      hash = "sha256-krVdvkXsMObyS3UX4lgB8qHd/BtgUDJjkNowP5cbaKE=";
    };
  };
in
stdenvNoCC.mkDerivation rec {
  pname = "pitchfork-bin";
  inherit version;
  src = sources.${stdenvNoCC.hostPlatform.system};

  sourceRoot = ".";

  nativeBuildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [ autoPatchelfHook ];

  buildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [ libgcc ];

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
    description = "Daemons with DX";
    homepage = "https://pitchfork.jdx.dev";
    changelog = "https://github.com/jdx/pitchfork/releases/tag/v${version}";
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
