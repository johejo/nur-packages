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
  version = "2.21.0";
  sources = {
    aarch64-darwin = fetchurl {
      url = "https://github.com/jdx/pitchfork/releases/download/v${version}/pitchfork-aarch64-apple-darwin.tar.gz";
      hash = "sha256-gIER48a0xyQHvmJ0SekcsPyMMVqpUKylhHQ76JbPjng=";
    };
    x86_64-linux = fetchurl {
      url = "https://github.com/jdx/pitchfork/releases/download/v${version}/pitchfork-x86_64-unknown-linux-gnu.tar.gz";
      hash = "sha256-rtsFJ5Bg7ko9eG3amNFOdmLTt7ugH+5wMJeW+eBMJYg=";
    };
    aarch64-linux = fetchurl {
      url = "https://github.com/jdx/pitchfork/releases/download/v${version}/pitchfork-aarch64-unknown-linux-gnu.tar.gz";
      hash = "sha256-qgWyTA/9zI10IShaapoylRtQ2QkRoobzYv7PnPQhFAI=";
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
