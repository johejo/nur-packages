{
  lib,
  stdenvNoCC,
  fetchurl,
  curl,
  installShellFiles,
  jq,
  nix-update,
  versionCheckHook,
  writeShellApplication,
  bubblewrap,
  makeWrapper,
  ...
}:

let
  version = "0.171.0";
  sources = {
    aarch64-darwin = fetchurl {
      url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-aarch64-apple-darwin.tar.gz";
      hash = "sha256-lBTIyWfxELEegyTAz6KyDwEglO+JARClYcku5TWiaBo=";
    };
    x86_64-linux = fetchurl {
      url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-x86_64-unknown-linux-musl.tar.gz";
      hash = "sha256-Abqi5HgJ+Fl75bL4q9Tk3+P7W8tuUEwvuqrZcFbBXo0=";
    };
    aarch64-linux = fetchurl {
      url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-aarch64-unknown-linux-musl.tar.gz";
      hash = "sha256-vPULg2OF5RvSl2qyu+krGwihy+N3EuuNvjeKp40khxw=";
    };
  };
  codeModeHostSources = {
    aarch64-darwin = fetchurl {
      url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-code-mode-host-aarch64-apple-darwin.tar.gz";
      hash = "sha256-egVgbCmwjMRLUGiemqPsF/dmpyar1hBcyfpTBu5jNac=";
    };
    x86_64-linux = fetchurl {
      url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-code-mode-host-x86_64-unknown-linux-musl.tar.gz";
      hash = "sha256-14YZAwwbjQpNnJxnZnwb+iOtnZ7cY9h//qqGeW89how=";
    };
    aarch64-linux = fetchurl {
      url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-code-mode-host-aarch64-unknown-linux-musl.tar.gz";
      hash = "sha256-dmnIgbeGabXxPduZmWtc7z+xDatbafQ74x0Z6C6c1is=";
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
    updateScript = [
      (lib.getExe (writeShellApplication {
        name = "update-codex-bin";
        runtimeInputs = [
          curl
          jq
          nix-update
        ];
        text = ''
          # Listing Codex's asset-heavy releases can time out on GitHub.
          # The latest endpoint returns only the current stable release.
          headers=()
          if [[ -n "''${GITHUB_TOKEN:-}" ]]; then
            headers+=(-H "Authorization: Bearer $GITHUB_TOKEN")
          fi
          version="$(curl --fail --silent --show-error --location --retry 5 \
            "''${headers[@]}" https://api.github.com/repos/openai/codex/releases/latest |
            jq -er '.tag_name | capture("^rust-v(?<version>[0-9]+[.][0-9]+[.][0-9]+)$").version')"
          # Refresh hashes even when a previous attempt already set the version.
          for targetVersion in "$version" skip; do
            nix-update codex-bin --flake \
              --version="$targetVersion" \
              --custom-dep=aarch64DarwinSrc \
              --custom-dep=x86_64LinuxSrc \
              --custom-dep=aarch64LinuxSrc \
              --custom-dep=aarch64DarwinCodeModeHostSrc \
              --custom-dep=x86_64LinuxCodeModeHostSrc \
              --custom-dep=aarch64LinuxCodeModeHostSrc
          done
        '';
      }))
    ];
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
