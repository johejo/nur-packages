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
  version = "0.162.0";
  sources = {
    aarch64-darwin = fetchurl {
      url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-aarch64-apple-darwin.tar.gz";
      hash = "sha256-mOlBOhvRZ65XNyOTn/F45tRPG7IdXNqWDb6y+mX0kQQ=";
    };
    x86_64-linux = fetchurl {
      url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-x86_64-unknown-linux-musl.tar.gz";
      hash = "sha256-ja9n9iYRYapZOdjUKlFgMtdgQGIWd5185gQPJCFA/3M=";
    };
    aarch64-linux = fetchurl {
      url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-aarch64-unknown-linux-musl.tar.gz";
      hash = "sha256-FRYqm1nt+OUSsnQU7At9si5kJKEmKw7uhmZkPg0pXC8=";
    };
  };
  codeModeHostSources = {
    aarch64-darwin = fetchurl {
      url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-code-mode-host-aarch64-apple-darwin.tar.gz";
      hash = "sha256-lFXBf6m6bon47CTr/TQZgl4sZRxW+L2N9xQUEebezcI=";
    };
    x86_64-linux = fetchurl {
      url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-code-mode-host-x86_64-unknown-linux-musl.tar.gz";
      hash = "sha256-3ui/PfY3xo4Ulbko1kO3bUrUT5Tk8O15/oSC+nniPZc=";
    };
    aarch64-linux = fetchurl {
      url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-code-mode-host-aarch64-unknown-linux-musl.tar.gz";
      hash = "sha256-GNmbBV0u9KKvUfEUSRm9iiCPT3ms44m3d1NB1pA89+k=";
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
