{
  lib,
  stdenvNoCC,
  fetchurl,
  nix-update-script,
  versionCheckHook,
  ...
}:

let
  version = "0.58.0";
  sources = {
    aarch64-darwin = fetchurl {
      url = "https://github.com/vectordotdev/vector/releases/download/v${version}/vector-${version}-arm64-apple-darwin.tar.gz";
      hash = "sha256-kYJJFZfxve2wjYSgUWFsYt7qdwqdkFtpdxLMZSaRlEk=";
    };
    x86_64-linux = fetchurl {
      url = "https://github.com/vectordotdev/vector/releases/download/v${version}/vector-${version}-x86_64-unknown-linux-musl.tar.gz";
      hash = "sha256-rQE93BZLgOQlzEA9IXTia4EWc4RtESXIC8e1Akgmzjk=";
    };
    aarch64-linux = fetchurl {
      url = "https://github.com/vectordotdev/vector/releases/download/v${version}/vector-${version}-aarch64-unknown-linux-musl.tar.gz";
      hash = "sha256-shr8i6I6b8qa7ASaMTum2l5Zt/wu0BiDnYMkHeWrlfc=";
    };
  };
in
stdenvNoCC.mkDerivation rec {
  pname = "vector-bin";
  inherit version;
  src = sources.${stdenvNoCC.hostPlatform.system};

  nativeInstallCheckInputs = [ versionCheckHook ];

  doInstallCheck = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 bin/vector $out/bin/vector
    runHook postInstall
  '';

  passthru = {
    aarch64DarwinSrc = sources.aarch64-darwin;
    x86_64LinuxSrc = sources.x86_64-linux;
    aarch64LinuxSrc = sources.aarch64-linux;
    updateScript = nix-update-script {
      extraArgs = [
        "--version-regex=v([0-9].*)"
        "--custom-dep=aarch64DarwinSrc"
        "--custom-dep=x86_64LinuxSrc"
        "--custom-dep=aarch64LinuxSrc"
      ];
    };
  };

  meta = {
    description = "High-performance observability data pipeline";
    homepage = "https://vector.dev";
    changelog = "https://github.com/vectordotdev/vector/releases/tag/v${version}";
    license = lib.licenses.mpl20;
    mainProgram = "vector";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
  };
}
