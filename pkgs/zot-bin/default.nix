{
  lib,
  stdenvNoCC,
  fetchurl,
  nix-update-script,
  autoPatchelfHook,
  versionCheckHook,
  ...
}:

let
  version = "2.1.21";
  sources = {
    aarch64-darwin = fetchurl {
      url = "https://github.com/project-zot/zot/releases/download/v${version}/zot-darwin-arm64";
      hash = "sha256-hcMpSVLCq9MJVTE2nlIudc+5wBM3wwh656AGFRjELQs=";
    };
    x86_64-linux = fetchurl {
      url = "https://github.com/project-zot/zot/releases/download/v${version}/zot-linux-amd64";
      hash = "sha256-h1HMDa9zljSDWjvYIG4wlMhNVS4sRi5KS6+A9A3ZJoU=";
    };
    aarch64-linux = fetchurl {
      url = "https://github.com/project-zot/zot/releases/download/v${version}/zot-linux-arm64";
      hash = "sha256-SeH5SK+OXG7VyAO61FCM9683vmwVt/soQBCZALkW60g=";
    };
  };
in
stdenvNoCC.mkDerivation rec {
  pname = "zot-bin";
  inherit version;
  src = sources.${stdenvNoCC.hostPlatform.system};

  dontUnpack = true;

  # zot's official binary release is built with -buildmode=pie.
  # -buildmode=pie makes the bin DYE and INTERP not EXEC.
  # INTERP bin that is not built on NixOS requires autoPatchelfHook.
  nativeBuildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [ autoPatchelfHook ];

  nativeInstallCheckInputs = [ versionCheckHook ];

  doInstallCheck = true;

  preVersionCheck = ''
    version="''${version#v}"
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/zot
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
    description = "Production-ready vendor-neutral OCI-native container image registry";
    homepage = "https://zotregistry.dev";
    changelog = "https://github.com/project-zot/zot/releases/tag/v${version}";
    license = lib.licenses.asl20;
    mainProgram = "zot";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
  };
}
