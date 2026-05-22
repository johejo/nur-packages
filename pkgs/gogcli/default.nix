{
  lib,
  stdenv,
  installShellFiles,
  versionCheckHook,
  source,
  ...
}:

let
  installShellCompletions = stdenv.buildPlatform.canExecute stdenv.hostPlatform;
in

stdenv.mkDerivation rec {
  pname = "gogcli";
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
    install -Dm755 gog $out/bin/gog
    runHook postInstall
  '';

  postInstall = lib.optionalString installShellCompletions ''
    installShellCompletion --cmd gog \
      --bash <($out/bin/gog completion bash) \
      --fish <($out/bin/gog completion fish) \
      --zsh <($out/bin/gog completion zsh)
  '';

  meta = {
    mainProgram = "gog";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
  };
}
