{
  lib,
  stdenvNoCC,
  fetchurl,
  nix-update-script,
  autoPatchelfHook,
  gcc,
  versionCheckHook,
  ...
}:

let
  version = "0.7.4";
  sources = {
    aarch64-darwin = fetchurl {
      url = "https://github.com/ushironoko/octorus/releases/download/v${version}/octorus-${version}-aarch64-apple-darwin.tar.gz";
      hash = "sha256-6LcXZDuF1fRVkLfIhyyvDdzN5I+AUuwrCA5JEIScPMk=";
    };
    x86_64-linux = fetchurl {
      url = "https://github.com/ushironoko/octorus/releases/download/v${version}/octorus-${version}-x86_64-unknown-linux-gnu.tar.gz";
      hash = "sha256-I+5/tOMFBFHuLCnVj1Fg4+1+S8dKSiLWFYr1tYDaUSo=";
    };
    aarch64-linux = fetchurl {
      url = "https://github.com/ushironoko/octorus/releases/download/v${version}/octorus-${version}-aarch64-unknown-linux-gnu.tar.gz";
      hash = "sha256-yAczrnYIL7jPWxpwdzQVR16wVqWnMnROSXKhYth9iik=";
    };
  };
in
stdenvNoCC.mkDerivation rec {
  pname = "octorus-bin";
  inherit version;
  src = sources.${stdenvNoCC.hostPlatform.system};

  sourceRoot = ".";

  nativeBuildInputs = [
    versionCheckHook
  ]
  ++ lib.optionals stdenvNoCC.hostPlatform.isLinux [ autoPatchelfHook ];

  buildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [ gcc.cc.lib ];

  doInstallCheck = true;
  preVersionCheck = ''
    version="''${version#v}"
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    binary="$(find . -type f -name or -print -quit)"
    install -Dm755 "$binary" $out/bin/or
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
    description = "A TUI tool for GitHub PR review, designed for Helix editor users";
    homepage = "https://github.com/ushironoko/octorus";
    license = lib.licenses.mit;
    changelog = "https://github.com/ushironoko/octorus/releases/tag/v${version}";
    mainProgram = "or";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
  };
}
