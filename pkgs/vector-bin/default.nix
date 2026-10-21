{
  lib,
  stdenvNoCC,
  fetchurl,
  nix-update-script,
  versionCheckHook,
  ...
}:

let
  version = "0.60.0";
  sources = {
    aarch64-darwin = fetchurl {
      url = "https://github.com/vectordotdev/vector/releases/download/v${version}/vector-${version}-arm64-apple-darwin.tar.gz";
      hash = "sha256-qlydiUFrOfGpCn8aCIqey7jIw6Vmn7hmCcnUqVj+Gig=";
    };
    x86_64-linux = fetchurl {
      url = "https://github.com/vectordotdev/vector/releases/download/v${version}/vector-${version}-x86_64-unknown-linux-musl.tar.gz";
      hash = "sha256-lYT0AuZ/6n/y3YRvCou7VvoylRve0RdJCT/zeA4VE88=";
    };
    aarch64-linux = fetchurl {
      url = "https://github.com/vectordotdev/vector/releases/download/v${version}/vector-${version}-aarch64-unknown-linux-musl.tar.gz";
      hash = "sha256-4phPgmqmG/PqmPukzM3iQ39kV5Sy+KPUXJfflZTc+9E=";
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
        "--use-github-releases"
        "--version-regex=^v([0-9]+\\.[0-9]+\\.[0-9]+)$"
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
