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
  version = "1.1.1";
  sources = {
    aarch64-darwin = fetchurl {
      url = "https://github.com/grafana/gcx/releases/download/v${version}/gcx_${version}_darwin_arm64.tar.gz";
      hash = "sha256-LezLm1epFMuKWuF6MuNg5I7MFS1kyJA3Mv0wNkTD4+k=";
    };
    x86_64-linux = fetchurl {
      url = "https://github.com/grafana/gcx/releases/download/v${version}/gcx_${version}_linux_amd64.tar.gz";
      hash = "sha256-f+h3j1pn6LYFdrqpnDnS7vaSCCmFAZtTpXiJveA/te0=";
    };
    aarch64-linux = fetchurl {
      url = "https://github.com/grafana/gcx/releases/download/v${version}/gcx_${version}_linux_arm64.tar.gz";
      hash = "sha256-GiIyb+HodUS7dx1OozQ5oSNcQLUiAMZ3J7aUNxr93kI=";
    };
  };
in
stdenvNoCC.mkDerivation rec {
  pname = "gcx-bin";
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
    install -Dm755 gcx $out/bin/gcx
    installShellCompletion --cmd gcx \
      --bash <($out/bin/gcx completion bash) \
      --fish <($out/bin/gcx completion fish) \
      --zsh <($out/bin/gcx completion zsh)
    runHook postInstall
  '';

  passthru = {
    aarch64DarwinSrc = sources.aarch64-darwin;
    x86_64LinuxSrc = sources.x86_64-linux;
    aarch64LinuxSrc = sources.aarch64-linux;
    updateScript = nix-update-script {
      extraArgs = [
        "--custom-dep=aarch64DarwinSrc"
        "--custom-dep=x86_64LinuxSrc"
        "--custom-dep=aarch64LinuxSrc"
      ];
    };
  };

  meta = {
    description = "Grafana CLI";
    homepage = "https://github.com/grafana/gcx";
    license = lib.licenses.asl20;
    changelog = "https://github.com/grafana/gcx/releases/tag/v${version}";
    mainProgram = "gcx";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
  };
}
