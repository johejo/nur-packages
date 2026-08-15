{
  lib,
  stdenvNoCC,
  installShellFiles,
  kwokSource,
  kwokctlSource,
  ...
}:

let
  version =
    assert kwokSource.version == kwokctlSource.version;
    kwokSource.version;
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
    install -Dm755 ${kwokSource.src} $out/bin/kwok
    install -Dm755 ${kwokctlSource.src} $out/bin/kwokctl
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

  meta = {
    description = "Kubernetes WithOut Kubelet";
    homepage = "https://github.com/kubernetes-sigs/kwok";
    changelog = "https://github.com/kubernetes-sigs/kwok/releases/tag/${version}";
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
