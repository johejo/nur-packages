{
  lib,
  stdenvNoCC,
  curl,
  fetchurl,
  gnused,
  installShellFiles,
  nix-update,
  versionCheckHook,
  writeShellApplication,
  ...
}:

let
  installShellCompletions = stdenvNoCC.buildPlatform.canExecute stdenvNoCC.hostPlatform;
  version = "1.3.23-stable";
  sources = {
    aarch64-darwin = fetchurl {
      url = "https://acli.atlassian.com/darwin/${version}/acli_${version}_darwin_arm64.tar.gz";
      hash = "sha256-r3j3uwaxN92reFJX+3Q2esMwRinH0kCvARenAMe1a2Q=";
    };
    x86_64-linux = fetchurl {
      url = "https://acli.atlassian.com/linux/${version}/acli_${version}_linux_amd64.tar.gz";
      hash = "sha256-Fnim0Kw2kEsbd4gZG1dAlio9yGlKpvPu6czY9HdJluU=";
    };
    aarch64-linux = fetchurl {
      url = "https://acli.atlassian.com/linux/${version}/acli_${version}_linux_arm64.tar.gz";
      hash = "sha256-XU6FgM8qrmgbwCu09hyKYvPvqPorBRs6X09WCpAnmmA=";
    };
  };
in
stdenvNoCC.mkDerivation {
  pname = "acli-bin";
  inherit version;
  src = sources.${stdenvNoCC.hostPlatform.system};

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

  passthru = {
    aarch64DarwinSrc = sources.aarch64-darwin;
    x86_64LinuxSrc = sources.x86_64-linux;
    aarch64LinuxSrc = sources.aarch64-linux;
    updateScript = [
      (lib.getExe (writeShellApplication {
        name = "update-acli-bin";
        runtimeInputs = [
          curl
          gnused
          nix-update
        ];
        text = ''
          version="$({
            curl -sSf https://raw.githubusercontent.com/atlassian/homebrew-acli/main/Formula/acli.rb
          } | sed -n 's/^ *version "\(.*\)"$/\1/p' | head -n1)"
          nix-update acli-bin --flake \
            --version="$version" \
            --custom-dep=aarch64DarwinSrc \
            --custom-dep=x86_64LinuxSrc \
            --custom-dep=aarch64LinuxSrc
        '';
      }))
    ];
  };

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
