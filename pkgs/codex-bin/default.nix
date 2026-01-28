{
  lib,
  stdenvNoCC,
  source,
  autoPatchelfHook,
  installShellFiles,
  versionCheckHook,
  ...
}:

let
  stdenv = stdenvNoCC;
  installShellCompletions = stdenv.buildPlatform.canExecute stdenv.hostPlatform;
in

stdenv.mkDerivation rec {
  pname = "codex-bin";
  inherit (source) version src;

  sourceRoot = ".";

  nativeBuildInputs = [ installShellFiles ] ++ lib.optionals stdenv.isLinux [ autoPatchelfHook ];
  nativeInstallCheckInputs = [ versionCheckHook ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    install -Dm755 codex-* $out/bin/codex
    runHook postInstall
  '';

  postInstall = lib.optionalString installShellCompletions ''
    installShellCompletion --cmd codex \
      --bash <($out/bin/codex completion bash) \
      --fish <($out/bin/codex completion fish) \
      --zsh <($out/bin/codex completion zsh)
  '';

  meta = {
    description = "Codex CLI from OpenAI";
    homepage = "https://github.com/openai/codex";
    license = lib.licenses.asl20;
    changelog = "https://github.com/openai/codex/releases/tag/${version}";
    mainProgram = "codex";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [
      "aarch64-darwin"
      "x86_64-linux"
    ];
  };
}
