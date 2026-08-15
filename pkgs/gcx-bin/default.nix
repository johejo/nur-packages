{
  lib,
  stdenvNoCC,
  source,
  installShellFiles,
  versionCheckHook,
  ...
}:

stdenvNoCC.mkDerivation rec {
  pname = "gcx-bin";
  inherit (source) version src;

  sourceRoot = ".";

  nativeBuildInputs = [ installShellFiles ];

  nativeInstallCheckInputs = [ versionCheckHook ];

  doInstallCheck = true;

  preVersionCheck = ''
    version="''${version#v}"
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 gcx $out/bin/gcx
    installShellCompletion --cmd gcx \
      --bash <($out/bin/gcx completion bash) \
      --fish <($out/bin/gcx completion fish) \
      --zsh <($out/bin/gcx completion zsh)
    runHook postInstall
  '';

  meta = {
    description = "Grafana CLI";
    homepage = "https://github.com/grafana/gcx";
    license = lib.licenses.asl20;
    changelog = "https://github.com/grafana/gcx/releases/tag/v${version}";
    mainProgram = "gcx";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
  };
}
