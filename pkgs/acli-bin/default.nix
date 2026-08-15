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
stdenvNoCC.mkDerivation {
  pname = "acli-bin";
  inherit (source) version src;

  sourceRoot = ".";

  nativeBuildInputs = [ installShellFiles ];

  nativeInstallCheckInputs = [ versionCheckHook ];

  doInstallCheck = true;

  preInstallCheck = ''
    export HOME=$TMPDIR
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 acli_*/acli $out/bin/acli
    runHook postInstall
  '';

  postInstall = lib.optionalString installShellCompletions ''
    export HOME=$TMPDIR
    installShellCompletion --cmd acli \
      --bash <($out/bin/acli completion bash) \
      --fish <($out/bin/acli completion fish) \
      --zsh <($out/bin/acli completion zsh)
  '';

  meta = {
    description = "Atlassian's official CLI for Jira and Confluence Cloud";
    homepage = "https://developer.atlassian.com/cloud/acli/";
    license = lib.licenses.unfree;
    mainProgram = "acli";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
  };
}
