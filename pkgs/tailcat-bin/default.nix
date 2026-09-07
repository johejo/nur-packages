{
  lib,
  stdenvNoCC,
  fetchurl,
  nix-update-script,
  versionCheckHook,
  ...
}:

let
  version = "0.6.0";
  sources = {
    x86_64-linux = fetchurl {
      url = "https://github.com/tailscale/tailcat/releases/download/v${version}/tailcat_${version}_linux_amd64.tar.gz";
      hash = "sha256-81l6mtAvXMpTj49ab4kSORC84+lhHR5ajpbV8tPMkP0=";
    };
    aarch64-linux = fetchurl {
      url = "https://github.com/tailscale/tailcat/releases/download/v${version}/tailcat_${version}_linux_arm64.tar.gz";
      hash = "sha256-//SPJdIjrqMfmFuuiiwBN4si5R6YXox9Jw4ahYZZhQY=";
    };
  };
in
stdenvNoCC.mkDerivation rec {
  pname = "tailcat-bin";
  inherit version;
  src = sources.${stdenvNoCC.hostPlatform.system};

  sourceRoot = ".";

  nativeInstallCheckInputs = [ versionCheckHook ];

  doInstallCheck = true;
  versionCheckProgramArg = "version";

  installPhase = ''
    runHook preInstall
    install -Dm755 tailcat $out/bin/tailcat
    install -Dm644 LICENSE $out/share/licenses/tailcat/LICENSE
    runHook postInstall
  '';

  passthru = {
    x86_64LinuxSrc = sources.x86_64-linux;
    aarch64LinuxSrc = sources.aarch64-linux;
    updateScript = nix-update-script {
      extraArgs = [
        "--system=${stdenvNoCC.hostPlatform.system}"
        "--version-regex=v(.*)"
        "--custom-dep=x86_64LinuxSrc"
        "--custom-dep=aarch64LinuxSrc"
      ];
    };
  };

  meta = {
    description = "Netcat-like CLI over Tailscale's data plane without its control plane";
    homepage = "https://github.com/tailscale/tailcat";
    changelog = "https://github.com/tailscale/tailcat/releases/tag/v${version}";
    license = lib.licenses.bsd3;
    mainProgram = "tailcat";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}
