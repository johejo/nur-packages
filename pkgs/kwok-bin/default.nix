{
  lib,
  stdenvNoCC,
  fetchurl,
  installShellFiles,
  nix-update-script,
  ...
}:

let
  version = "0.8.0";
  kwokSources = {
    aarch64-darwin = fetchurl {
      url = "https://github.com/kubernetes-sigs/kwok/releases/download/v${version}/kwok-darwin-arm64";
      hash = "sha256-aaBk7JjTeETZ10K1so/1eCVlmpg8zD4gjappSLlNZLo=";
    };
    x86_64-linux = fetchurl {
      url = "https://github.com/kubernetes-sigs/kwok/releases/download/v${version}/kwok-linux-amd64";
      hash = "sha256-9aQ4Wirhud1/isrhjgAqdcDruhJK6dclmqja21BxH0Y=";
    };
    aarch64-linux = fetchurl {
      url = "https://github.com/kubernetes-sigs/kwok/releases/download/v${version}/kwok-linux-arm64";
      hash = "sha256-Yo99J3hg9SSip3XCF63MWIKOe1mrCTNoAxV4TxuLDjc=";
    };
  };
  kwokctlSources = {
    aarch64-darwin = fetchurl {
      url = "https://github.com/kubernetes-sigs/kwok/releases/download/v${version}/kwokctl-darwin-arm64";
      hash = "sha256-kyOlmtucJ4VL0qdmUq0AJYvLtorMQKug3CHjYrZ7fWo=";
    };
    x86_64-linux = fetchurl {
      url = "https://github.com/kubernetes-sigs/kwok/releases/download/v${version}/kwokctl-linux-amd64";
      hash = "sha256-1XQxZsZXKD1ugnx8TCDKz9kAn9lIMPBnGMp7LHCZRh8=";
    };
    aarch64-linux = fetchurl {
      url = "https://github.com/kubernetes-sigs/kwok/releases/download/v${version}/kwokctl-linux-arm64";
      hash = "sha256-WmQrJ9PpdfNgQNIVZAzZD7SmPLb8oK1YZaYbzZyBBRs=";
    };
  };
  kwokSrc = kwokSources.${stdenvNoCC.hostPlatform.system};
  kwokctlSrc = kwokctlSources.${stdenvNoCC.hostPlatform.system};
  installShellCompletions = stdenvNoCC.buildPlatform.canExecute stdenvNoCC.hostPlatform;
in

stdenvNoCC.mkDerivation {
  pname = "kwok-bin";
  inherit version;

  dontUnpack = true;

  nativeBuildInputs = [ installShellFiles ];

  doInstallCheck = installShellCompletions;

  installPhase = ''
    runHook preInstall
    install -Dm755 ${kwokSrc} $out/bin/kwok
    install -Dm755 ${kwokctlSrc} $out/bin/kwokctl
    runHook postInstall
  '';

  postInstall = lib.optionalString installShellCompletions ''
    installShellCompletion --cmd kwok \
      --bash <($out/bin/kwok completion bash) \
      --fish <($out/bin/kwok completion fish) \
      --zsh <($out/bin/kwok completion zsh)
    installShellCompletion --cmd kwokctl \
      --bash <($out/bin/kwokctl completion bash) \
      --fish <($out/bin/kwokctl completion fish) \
      --zsh <($out/bin/kwokctl completion zsh)
  '';

  installCheckPhase = ''
    runHook preInstallCheck
    $out/bin/kwok --version | grep -F ${lib.escapeShellArg version}
    $out/bin/kwokctl --version | grep -F ${lib.escapeShellArg version}
    runHook postInstallCheck
  '';

  passthru = {
    aarch64DarwinKwokSrc = kwokSources.aarch64-darwin;
    x86_64LinuxKwokSrc = kwokSources.x86_64-linux;
    aarch64LinuxKwokSrc = kwokSources.aarch64-linux;
    aarch64DarwinKwokctlSrc = kwokctlSources.aarch64-darwin;
    x86_64LinuxKwokctlSrc = kwokctlSources.x86_64-linux;
    aarch64LinuxKwokctlSrc = kwokctlSources.aarch64-linux;
    updateScript = nix-update-script {
      extraArgs = [
        "--custom-dep=aarch64DarwinKwokSrc"
        "--custom-dep=x86_64LinuxKwokSrc"
        "--custom-dep=aarch64LinuxKwokSrc"
        "--custom-dep=aarch64DarwinKwokctlSrc"
        "--custom-dep=x86_64LinuxKwokctlSrc"
        "--custom-dep=aarch64LinuxKwokctlSrc"
      ];
    };
  };

  meta = {
    description = "Kubernetes WithOut Kubelet";
    homepage = "https://github.com/kubernetes-sigs/kwok";
    changelog = "https://github.com/kubernetes-sigs/kwok/releases/tag/v${version}";
    license = lib.licenses.asl20;
    mainProgram = "kwokctl";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
  };
}
