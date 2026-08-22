{
  lib,
  stdenvNoCC,
  fetchurl,
  nix-update-script,
  versionCheckHook,
  ...
}:

let
  version = "0.0.66";
  sources = {
    aarch64-darwin = fetchurl {
      url = "https://github.com/containers/kubernetes-mcp-server/releases/download/v${version}/kubernetes-mcp-server-darwin-arm64";
      hash = "sha256-Ueotf0Us+i+TBCXjsYcCM76vn5LiEF/JIwVWXyk8kio=";
    };
    x86_64-linux = fetchurl {
      url = "https://github.com/containers/kubernetes-mcp-server/releases/download/v${version}/kubernetes-mcp-server-linux-amd64";
      hash = "sha256-aSp7KDqWFAMR/UbxO4NzZXsum/5mCja7ZDToxC2Jnbw=";
    };
    aarch64-linux = fetchurl {
      url = "https://github.com/containers/kubernetes-mcp-server/releases/download/v${version}/kubernetes-mcp-server-linux-arm64";
      hash = "sha256-NMFKAa0IQwLBgYSPhBUbwlhY8IGOJztNsbct5yavHuU=";
    };
  };
in
stdenvNoCC.mkDerivation rec {
  pname = "kubernetes-mcp-server-bin";
  inherit version;
  src = sources.${stdenvNoCC.hostPlatform.system};

  dontUnpack = true;

  nativeInstallCheckInputs = [ versionCheckHook ];

  doInstallCheck = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/kubernetes-mcp-server
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
    description = "A Model Context Protocol (MCP) server for Kubernetes and OpenShift";
    homepage = "https://github.com/containers/kubernetes-mcp-server";
    changelog = "https://github.com/containers/kubernetes-mcp-server/releases/tag/v${version}";
    license = lib.licenses.asl20;
    mainProgram = "kubernetes-mcp-server";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
  };
}
