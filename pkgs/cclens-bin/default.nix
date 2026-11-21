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
  version = "0.5.0";
  sources = {
    aarch64-darwin = fetchurl {
      url = "https://github.com/lambdalisue/cclens/releases/download/v${version}/cclens-v${version}-aarch64-apple-darwin.tar.gz";
      hash = "sha256-3Aw4YDKpLFom8OG9xVOwWfxIimswXsDGaw4g7rM/2Y0=";
    };
    x86_64-linux = fetchurl {
      url = "https://github.com/lambdalisue/cclens/releases/download/v${version}/cclens-v${version}-x86_64-unknown-linux-gnu.tar.gz";
      hash = "sha256-Bz10QzJ516VRb2Vqm8ADBHGlhSq6QFuH3zqOlgkxnAY=";
    };
    aarch64-linux = fetchurl {
      url = "https://github.com/lambdalisue/cclens/releases/download/v${version}/cclens-v${version}-aarch64-unknown-linux-gnu.tar.gz";
      hash = "sha256-SKWTwc6Za6pA9oXZAqLB2WCA240JPSU5vN2O8lNEF5Q=";
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
