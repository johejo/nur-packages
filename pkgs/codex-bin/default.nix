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
  version = "0.160.1";
  sources = {
    aarch64-darwin = fetchurl {
      url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-aarch64-apple-darwin.tar.gz";
      hash = "sha256-ZwrysEnZyVr7dNfaOF8wxQM9E6BxdQAd2JWMUZRJhNA=";
    };
    x86_64-linux = fetchurl {
      url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-x86_64-unknown-linux-musl.tar.gz";
      hash = "sha256-kiZYG+WS0Y9+f3QKNS/bY6ph5F459+ubCdOIjIS7oz8=";
    };
    aarch64-linux = fetchurl {
      url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-aarch64-unknown-linux-musl.tar.gz";
      hash = "sha256-9U3FhSBCRFv0HaOqMRVvPLAvUsWhoEB03nPcVZj34fc=";
    };
  };
  codeModeHostSources = {
    aarch64-darwin = fetchurl {
      url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-code-mode-host-aarch64-apple-darwin.tar.gz";
      hash = "sha256-blAt9p2SIPowWww8fBe6jzGrHUWR/BQAhNu4I+gAx9s=";
    };
    x86_64-linux = fetchurl {
      url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-code-mode-host-x86_64-unknown-linux-musl.tar.gz";
      hash = "sha256-imkgfZdUWsdTtlhZdOHmekxRrl3qzwZRfbUSuyXg48I=";
    };
    aarch64-linux = fetchurl {
      url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-code-mode-host-aarch64-unknown-linux-musl.tar.gz";
      hash = "sha256-5eAn5mie/aLjVwqmABefDrsYYygDNQ4VLtbJuX3Pl0E=";
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
