{
  lib,
  stdenv,
  source,
  autoPatchelfHook,
  installShellFiles,
  versionCheckHook,
  openssl,
  ...
}:

stdenv.mkDerivation rec {
  pname = "codex-bin";
  inherit (source) version src;

  sourceRoot = ".";

  nativeBuildInputs = [ installShellFiles ] ++ lib.optionals stdenv.isLinux [ autoPatchelfHook ];

  nativeInstallCheckInputs = [ versionCheckHook ];

  buildInputs = [
    stdenv.cc.cc.lib
    openssl
  ];

  doInstallCheck = true;

  preVersionCheck = ''
    version="''${version#rust-v}"
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    install -Dm755 codex-* $out/bin/codex
    autoPatchelf $out/bin/codex
    runHook postInstall
  '';

  postInstall = ''
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
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
  };
}
