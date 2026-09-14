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
  version = "4.0.1-0";
  sources = {
    aarch64-darwin = fetchurl {
      url = "https://github.com/suzuki-shunsuke/ghtkn/releases/download/v${version}/ghtkn_darwin_arm64.tar.gz";
      hash = "sha256-1iwu91yFHsRH0X45IdXuKwOqs1gHU36eObRRjyOXlgY=";
    };
    x86_64-linux = fetchurl {
      url = "https://github.com/suzuki-shunsuke/ghtkn/releases/download/v${version}/ghtkn_linux_amd64.tar.gz";
      hash = "sha256-725ndzEb5EVcSeyN/o04B0s4btQ8uTfNEtKHVwtJau0=";
    };
    aarch64-linux = fetchurl {
      url = "https://github.com/suzuki-shunsuke/ghtkn/releases/download/v${version}/ghtkn_linux_arm64.tar.gz";
      hash = "sha256-KhaFfiHTHlq1RR+RmkYybnsuwnXnqFGaS+pETRyFvBY=";
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
