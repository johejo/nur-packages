{
  lib,
  stdenvNoCC,
  fetchurl,
  nix-update-script,
  autoPatchelfHook,
  libgcc,
  versionCheckHook,
  ...
}:

let
  version = "2.33.0";
  sources = {
    aarch64-darwin = fetchurl {
      url = "https://github.com/jdx/pitchfork/releases/download/v${version}/pitchfork-aarch64-apple-darwin.tar.gz";
      hash = "sha256-7rcTgc9uK4dXXMO8BqmKLxxat0Gs0eVSLN5603J/nTI=";
    };
    x86_64-linux = fetchurl {
      url = "https://github.com/jdx/pitchfork/releases/download/v${version}/pitchfork-x86_64-unknown-linux-gnu.tar.gz";
      hash = "sha256-qC89qgoM37BWKeXX4Y4busdX0X5X2A7bAXnrFnVVuZw=";
    };
    aarch64-linux = fetchurl {
      url = "https://github.com/jdx/pitchfork/releases/download/v${version}/pitchfork-aarch64-unknown-linux-gnu.tar.gz";
      hash = "sha256-wfu6JFgKfqZiubE88pWPeUNYbLou/DvKK6RNMz5NLWo=";
    };
  };
in
stdenvNoCC.mkDerivation rec {
  pname = "pitchfork-bin";
  inherit version;
  src = sources.${stdenvNoCC.hostPlatform.system};

  sourceRoot = ".";

  nativeBuildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [ autoPatchelfHook ];

  buildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [ libgcc ];

  # Preserve ELF section ordering to avoid a startup segfault after patching.
  patchelfFlags = [ "--no-sort" ];

  nativeInstallCheckInputs = [ versionCheckHook ];

  doInstallCheck = true;
  preVersionCheck = ''
    version="''${version#v}"
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 pitchfork $out/bin/pitchfork
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
    description = "Daemons with DX";
    homepage = "https://pitchfork.jdx.dev";
    changelog = "https://github.com/jdx/pitchfork/releases/tag/v${version}";
    license = lib.licenses.mit;
    mainProgram = "pitchfork";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
  };
}
