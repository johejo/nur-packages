{
  lib,
  stdenvNoCC,
  source,
  installShellFiles,
  versionCheckHook,
  ...
}:

let
  installShellCompletions = stdenvNoCC.buildPlatform.canExecute stdenvNoCC.hostPlatform;
in
stdenvNoCC.mkDerivation rec {
  pname = "ghtkn-bin";
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
    install -Dm755 ghtkn $out/bin/ghtkn
    runHook postInstall
  '';

  postInstall = lib.optionalString installShellCompletions ''
    installShellCompletion --cmd ghtkn \
      --bash <($out/bin/ghtkn completion bash) \
      --fish <($out/bin/ghtkn completion fish) \
      --zsh <($out/bin/ghtkn completion zsh)
  '';

  meta = {
    description = "Create GitHub App User Access Tokens for secure local development";
    homepage = "https://github.com/suzuki-shunsuke/ghtkn";
    license = lib.licenses.mit;
    changelog = "https://github.com/suzuki-shunsuke/ghtkn/releases/tag/${version}";
    mainProgram = "ghtkn";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
  };
}
