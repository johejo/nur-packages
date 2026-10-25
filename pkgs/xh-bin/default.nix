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
  version = "0.26.3";
  sources = {
    aarch64-darwin = fetchurl {
      url = "https://github.com/ducaale/xh/releases/download/v${version}/xh-v${version}-aarch64-apple-darwin.tar.gz";
      hash = "sha256-UNYb11WUJ1KwVCl6FhLsGRZU8Tf4k5Zzzag8aGy1sPI=";
    };
    x86_64-linux = fetchurl {
      url = "https://github.com/ducaale/xh/releases/download/v${version}/xh-v${version}-x86_64-unknown-linux-musl.tar.gz";
      hash = "sha256-y79TvXYAfVfZXkvti6f7O3/Owir0vfwf8RnNXeNR508=";
    };
    aarch64-linux = fetchurl {
      url = "https://github.com/ducaale/xh/releases/download/v${version}/xh-v${version}-aarch64-unknown-linux-musl.tar.gz";
      hash = "sha256-pF2MtsI0xoUPn8I5X8NUSrdpH7URI38AF5rtuhvNUl4=";
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
