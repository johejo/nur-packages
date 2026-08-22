{
  lib,
  stdenvNoCC,
  fetchurl,
  nix-update-script,
  installShellFiles,
  versionCheckHook,
  ...
}:

let
  installShellCompletions = stdenvNoCC.buildPlatform.canExecute stdenvNoCC.hostPlatform;
  version = "0.37.0";
  sources = {
    aarch64-darwin = fetchurl {
      url = "https://github.com/steipete/gogcli/releases/download/v${version}/gogcli_${version}_darwin_arm64.tar.gz";
      hash = "sha256-ihwMLAJk/cYCzOULREMeEFaSafmOBUq1UDPGUqlrfGE=";
    };
    x86_64-linux = fetchurl {
      url = "https://github.com/steipete/gogcli/releases/download/v${version}/gogcli_${version}_linux_amd64.tar.gz";
      hash = "sha256-kF/tC/q6+l3ecYnlBkKz+jHX/EqtUKjSfSuSBx2HWWI=";
    };
    aarch64-linux = fetchurl {
      url = "https://github.com/steipete/gogcli/releases/download/v${version}/gogcli_${version}_linux_arm64.tar.gz";
      hash = "sha256-Sr3pDE50zrEl8/3Ydnb/eVjon3ggl4/6Ed4mruBuchw=";
    };
  };
in

stdenvNoCC.mkDerivation rec {
  pname = "gogcli-bin";
  inherit version;
  src = sources.${stdenvNoCC.hostPlatform.system};

  sourceRoot = ".";

  nativeBuildInputs = [ installShellFiles ];

  nativeInstallCheckInputs = [ versionCheckHook ];

  doInstallCheck = true;

  preVersionCheck = ''
    version="''${version#v}"
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 gog $out/bin/gog
    runHook postInstall
  '';

  postInstall = lib.optionalString installShellCompletions ''
    installShellCompletion --cmd gog \
      --bash <($out/bin/gog completion bash) \
      --fish <($out/bin/gog completion fish) \
      --zsh <($out/bin/gog completion zsh)
  '';

  passthru = {
    aarch64DarwinSrc = sources.aarch64-darwin;
    x86_64LinuxSrc = sources.x86_64-linux;
    aarch64LinuxSrc = sources.aarch64-linux;
    updateScript = nix-update-script {
      extraArgs = [
        "--url=https://github.com/openclaw/gogcli"
        "--custom-dep=aarch64DarwinSrc"
        "--custom-dep=x86_64LinuxSrc"
        "--custom-dep=aarch64LinuxSrc"
      ];
    };
  };

  meta = {
    homepage = "https://github.com/openclaw/gogcli";
    mainProgram = "gog";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
  };
}
