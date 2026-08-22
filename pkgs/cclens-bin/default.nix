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
  version = "0.1.1";
  sources = {
    aarch64-darwin = fetchurl {
      url = "https://github.com/lambdalisue/cclens/releases/download/v${version}/cclens-v${version}-aarch64-apple-darwin.tar.gz";
      hash = "sha256-17G1KWOE+CQhYpY9/KpeD1L58CV9dnaR8EutqPlKgz4=";
    };
    x86_64-linux = fetchurl {
      url = "https://github.com/lambdalisue/cclens/releases/download/v${version}/cclens-v${version}-x86_64-unknown-linux-gnu.tar.gz";
      hash = "sha256-4BtEDsWQBZvWF75tK5dQy0jmsfFeqhUkWJW8Wg3cNAw=";
    };
    aarch64-linux = fetchurl {
      url = "https://github.com/lambdalisue/cclens/releases/download/v${version}/cclens-v${version}-aarch64-unknown-linux-gnu.tar.gz";
      hash = "sha256-cksURAmE28ssZECXp+cr0q50pQTAf+VoflJcAo3CRkw=";
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
