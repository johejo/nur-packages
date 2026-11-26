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
  version = "0.172.0";
  sources = {
    aarch64-darwin = fetchurl {
      url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-aarch64-apple-darwin.tar.gz";
      hash = "sha256-vRIfir1rKLP8R22gSjSOJag+ie2hnTkQf2j46WYFMJI=";
    };
    x86_64-linux = fetchurl {
      url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-x86_64-unknown-linux-musl.tar.gz";
      hash = "sha256-ojQqj39o8Ii+MGIMz+nLhBYsk6a1YXeFWWHNo+1r45I=";
    };
    aarch64-linux = fetchurl {
      url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-aarch64-unknown-linux-musl.tar.gz";
      hash = "sha256-C5lSbBhaRCX+lqIhT7e2pqf3wUcYg7evvr6X4V6D554=";
    };
  };
  codeModeHostSources = {
    aarch64-darwin = fetchurl {
      url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-code-mode-host-aarch64-apple-darwin.tar.gz";
      hash = "sha256-6rJPiObiDIgdjBG39w7iIP0ZqUxYbsa86tEqIOAstuQ=";
    };
    x86_64-linux = fetchurl {
      url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-code-mode-host-x86_64-unknown-linux-musl.tar.gz";
      hash = "sha256-ILCkvPMyQVpZl5FMlD0Er2w2J68MN5/b9lQAVQ41K7Q=";
    };
    aarch64-linux = fetchurl {
      url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-code-mode-host-aarch64-unknown-linux-musl.tar.gz";
      hash = "sha256-tmN+uqNT6jqTTUDjdRKJqaOe2Bz5b+P6Ov6hHjhA3Gg=";
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
