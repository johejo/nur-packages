{
  lib,
  stdenvNoCC,
  fetchurl,
  installShellFiles,
  nix-update-script,
  versionCheckHook,
  bubblewrap,
  makeWrapper,
  ...
}:

let
  version = "0.156.1";
  sources = {
    aarch64-darwin = fetchurl {
      url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-aarch64-apple-darwin.tar.gz";
      hash = "sha256-K9ZK8U3t1HeV8va/1dElz3kZmswse6IiFE4IEnERpco=";
    };
    x86_64-linux = fetchurl {
      url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-x86_64-unknown-linux-musl.tar.gz";
      hash = "sha256-r/RlOag6/4bjxixZK84sUNlTkfnfKJr68DpQwB0UUz0=";
    };
    aarch64-linux = fetchurl {
      url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-aarch64-unknown-linux-musl.tar.gz";
      hash = "sha256-VY4SqqbayzNexHJAv5ch24pUdGgG1k8BGFpAP0T3m3I=";
    };
  };
  codeModeHostSources = {
    aarch64-darwin = fetchurl {
      url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-code-mode-host-aarch64-apple-darwin.tar.gz";
      hash = "sha256-JiXQI+K24D0rzEN6Pg4IMcJdPHItKFRjio50kh/3m9k=";
    };
    x86_64-linux = fetchurl {
      url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-code-mode-host-x86_64-unknown-linux-musl.tar.gz";
      hash = "sha256-qSnaqfagvdwAwMnmQC3xF7ElrNlvnVVPbJnDLH5mxgg=";
    };
    aarch64-linux = fetchurl {
      url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-code-mode-host-aarch64-unknown-linux-musl.tar.gz";
      hash = "sha256-QBmBOLA3mP+owNpMgnqMpYlndOoQS3EQwqLAx1YMvpQ=";
    };
  };
  codeModeHostSrc = codeModeHostSources.${stdenvNoCC.hostPlatform.system};
in
stdenvNoCC.mkDerivation rec {
  pname = "codex-bin";
  inherit version;
  src = sources.${stdenvNoCC.hostPlatform.system};

  sourceRoot = ".";

  nativeBuildInputs = [
    installShellFiles
  ]
  ++ lib.optionals stdenvNoCC.hostPlatform.isLinux [ makeWrapper ];

  nativeInstallCheckInputs = [ versionCheckHook ];

  doInstallCheck = true;

  preVersionCheck = ''
    version="${version}"
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    install -Dm755 codex-* $out/bin/codex
    tar -xzf ${codeModeHostSrc}
    install -Dm755 codex-code-mode-host-* $out/bin/codex-code-mode-host
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
  ''
  + lib.optionalString stdenvNoCC.hostPlatform.isLinux ''
    wrapCodexBubblewrap() {
      wrapProgram $out/bin/codex \
        --prefix PATH : ${lib.makeBinPath [ bubblewrap ]}
    }

    postFixupHooks+=(wrapCodexBubblewrap)
  '';

  passthru = {
    aarch64DarwinSrc = sources.aarch64-darwin;
    x86_64LinuxSrc = sources.x86_64-linux;
    aarch64LinuxSrc = sources.aarch64-linux;
    aarch64DarwinCodeModeHostSrc = codeModeHostSources.aarch64-darwin;
    x86_64LinuxCodeModeHostSrc = codeModeHostSources.x86_64-linux;
    aarch64LinuxCodeModeHostSrc = codeModeHostSources.aarch64-linux;
    updateScript = nix-update-script {
      extraArgs = [
        "--use-github-releases"
        "--version-regex=^rust-v([0-9]+[.][0-9]+[.][0-9]+)$"
        "--custom-dep=aarch64DarwinSrc"
        "--custom-dep=x86_64LinuxSrc"
        "--custom-dep=aarch64LinuxSrc"
        "--custom-dep=aarch64DarwinCodeModeHostSrc"
        "--custom-dep=x86_64LinuxCodeModeHostSrc"
        "--custom-dep=aarch64LinuxCodeModeHostSrc"
      ];
    };
  };

  meta = {
    description = "Codex CLI from OpenAI";
    homepage = "https://github.com/openai/codex";
    license = lib.licenses.asl20;
    changelog = "https://github.com/openai/codex/releases/tag/rust-v${version}";
    mainProgram = "codex";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
  };
}
