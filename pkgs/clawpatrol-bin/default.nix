{
  lib,
  stdenvNoCC,
  fetchurl,
  nix-update-script,
  versionCheckHook,
  ...
}:

let
  version = "0.5.14";
  sources = {
    aarch64-darwin = fetchurl {
      url = "https://github.com/denoland/clawpatrol/releases/download/v${version}/clawpatrol-darwin-arm64";
      hash = "sha256-Xf3CzgwAW2ZiUf1Aet/fzfTZa12+ZZy2AjpylyEYvxM=";
    };
    x86_64-linux = fetchurl {
      url = "https://github.com/denoland/clawpatrol/releases/download/v${version}/clawpatrol-linux-amd64";
      hash = "sha256-rcOIccIGTm176zSMz5mqLWiLdR5vhZtJ6krfQit7I1Y=";
    };
    aarch64-linux = fetchurl {
      url = "https://github.com/denoland/clawpatrol/releases/download/v${version}/clawpatrol-linux-arm64";
      hash = "sha256-yccg0UVH8IOEykbAJEZzOzWNOS+5WeGGZIcp/ckZi24=";
    };
  };
in
stdenvNoCC.mkDerivation rec {
  pname = "clawpatrol-bin";
  inherit version;
  src = sources.${stdenvNoCC.hostPlatform.system};

  dontUnpack = true;

  nativeInstallCheckInputs = [ versionCheckHook ];

  doInstallCheck = true;

  preVersionCheck = ''
    version="''${version#v}"
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/clawpatrol
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
    description = "Security firewall for agents";
    homepage = "https://clawpatrol.dev";
    changelog = "https://github.com/denoland/clawpatrol/releases/tag/v${version}";
    license = lib.licenses.mit;
    mainProgram = "clawpatrol";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
  };
}
