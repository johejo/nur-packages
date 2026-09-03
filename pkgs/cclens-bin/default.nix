{
  lib,
  stdenvNoCC,
  fetchurl,
  nix-update-script,
  autoPatchelfHook,
  libgcc,
  ...
}:

let
  version = "0.2.0";
  sources = {
    aarch64-darwin = fetchurl {
      url = "https://github.com/lambdalisue/cclens/releases/download/v${version}/cclens-v${version}-aarch64-apple-darwin.tar.gz";
      hash = "sha256-FgDq7KUflcNI0FDfR/5s+XCGRhI0gzN0lVbMKA+Oo4I=";
    };
    x86_64-linux = fetchurl {
      url = "https://github.com/lambdalisue/cclens/releases/download/v${version}/cclens-v${version}-x86_64-unknown-linux-gnu.tar.gz";
      hash = "sha256-cyeNCP7iO9xe4cl393JTk16kPDVJQxNLR4DA5+Wo3ik=";
    };
    aarch64-linux = fetchurl {
      url = "https://github.com/lambdalisue/cclens/releases/download/v${version}/cclens-v${version}-aarch64-unknown-linux-gnu.tar.gz";
      hash = "sha256-VFMnS/LlZViRT4waMVioij0t+A7XkFZ6PwNIGxDwAQc=";
    };
  };
in
stdenvNoCC.mkDerivation rec {
  pname = "cclens-bin";
  inherit version;
  src = sources.${stdenvNoCC.hostPlatform.system};

  sourceRoot = ".";

  nativeBuildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [ autoPatchelfHook ];

  buildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [ libgcc ];

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
    description = "Lens onto your Claude Code usage";
    homepage = "https://github.com/lambdalisue/cclens";
    changelog = "https://github.com/lambdalisue/cclens/releases/tag/v${version}";
    mainProgram = "cclens";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
  };
}
