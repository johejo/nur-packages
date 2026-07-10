{
  lib,
  stdenv,
  source,
  autoPatchelfHook,
  installShellFiles,
  versionCheckHook,
  openssl,
  libcap,
  zlib,
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
  ]
  ++ lib.optionals stdenv.isLinux [
    libcap
    zlib
  ];

  doInstallCheck = true;

  preVersionCheck = ''
    version="''${version#rust-v}"
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    install -Dm755 codex-* $out/bin/codex
    runHook postInstall
  '';

  preFixup = ''
    generateCodexCompletions() {
      installShellCompletion --cmd codex \
        --bash <($out/bin/codex completion bash) \
        --fish <($out/bin/codex completion fish) \
        --zsh <($out/bin/codex completion zsh)
    }

    postFixupHooks+=(generateCodexCompletions)
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
