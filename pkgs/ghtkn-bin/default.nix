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
  installShellCompletions = stdenvNoCC.buildPlatform.canExecute stdenvNoCC.hostPlatform;
  version = "0.4.0";
  sources = {
    aarch64-darwin = fetchurl {
      url = "https://github.com/suzuki-shunsuke/ghtkn/releases/download/v${version}/ghtkn_darwin_arm64.tar.gz";
      hash = "sha256-tSq6R9nHd+HusgXtS0PSguvgcqdvM+vR5cZpAYffOvc=";
    };
    x86_64-linux = fetchurl {
      url = "https://github.com/suzuki-shunsuke/ghtkn/releases/download/v${version}/ghtkn_linux_amd64.tar.gz";
      hash = "sha256-Lbzc0NQJZv2hNSKyPGUiuMZoLw5xkwExln4PXXDxJSY=";
    };
    aarch64-linux = fetchurl {
      url = "https://github.com/suzuki-shunsuke/ghtkn/releases/download/v${version}/ghtkn_linux_arm64.tar.gz";
      hash = "sha256-M6Dh+RU1/AqQDdwI4sGCsd69VlYSQVPECMLJapr8Qjg=";
    };
  };
in
stdenvNoCC.mkDerivation rec {
  pname = "ghtkn-bin";
  inherit version;
  src = sources.${stdenvNoCC.hostPlatform.system};

  sourceRoot = ".";

  nativeBuildInputs = [ installShellFiles ];

  nativeInstallCheckInputs = [ versionCheckHook ];

  doInstallCheck = true;

  preVersionCheck = ''
    version="''${version#v}"
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 ghtkn $out/bin/ghtkn
    runHook postInstall
  '';

  postInstall = lib.optionalString installShellCompletions ''
    installShellCompletion --cmd ghtkn \
      --bash <($out/bin/ghtkn completion bash) \
      --fish <($out/bin/ghtkn completion fish) \
      --zsh <($out/bin/ghtkn completion zsh)
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
    description = "Create GitHub App User Access Tokens for secure local development";
    homepage = "https://github.com/suzuki-shunsuke/ghtkn";
    license = lib.licenses.mit;
    changelog = "https://github.com/suzuki-shunsuke/ghtkn/releases/tag/v${version}";
    mainProgram = "ghtkn";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
  };
}
