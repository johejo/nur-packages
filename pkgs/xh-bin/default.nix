{
  lib,
  stdenvNoCC,
  fetchurl,
  nix-update-script,
  installShellFiles,
  versionCheckHook,
  ...
}:

let
  version = "0.26.2";
  sources = {
    aarch64-darwin = fetchurl {
      url = "https://github.com/ducaale/xh/releases/download/v${version}/xh-v${version}-aarch64-apple-darwin.tar.gz";
      hash = "sha256-zFc50GGoRp0AEcoKuS1KXNcmzFbw7zAQiVOxGfVNBxk=";
    };
    x86_64-linux = fetchurl {
      url = "https://github.com/ducaale/xh/releases/download/v${version}/xh-v${version}-x86_64-unknown-linux-musl.tar.gz";
      hash = "sha256-jFO2ojQ1dU+eLqirjA0ClqGSFAS4gTLPmzZP9ujCKm4=";
    };
    aarch64-linux = fetchurl {
      url = "https://github.com/ducaale/xh/releases/download/v${version}/xh-v${version}-aarch64-unknown-linux-musl.tar.gz";
      hash = "sha256-OkSQCorFP2FKoM0dLlTs9Ok1hDhMGtCRqhjXmSaG1+s=";
    };
  };
in
stdenvNoCC.mkDerivation {
  pname = "xh-bin";
  inherit version;
  src = sources.${stdenvNoCC.hostPlatform.system};

  nativeBuildInputs = [ installShellFiles ];
  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 xh $out/bin/xh
    ln -s xh $out/bin/xhs
    installManPage doc/xh.1
    installShellCompletion --cmd xh \
      --bash completions/xh.bash \
      --fish completions/xh.fish \
      --zsh completions/_xh

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
    description = "Friendly and fast tool for sending HTTP requests";
    homepage = "https://github.com/ducaale/xh";
    changelog = "https://github.com/ducaale/xh/releases/tag/v${version}";
    license = lib.licenses.mit;
    mainProgram = "xh";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
  };
}
