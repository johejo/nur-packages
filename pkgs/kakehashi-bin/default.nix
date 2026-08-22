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
  version = "1.0.0";
  sources = {
    aarch64-darwin = fetchurl {
      url = "https://github.com/atusy/kakehashi/releases/download/v${version}/kakehashi-v${version}-aarch64-apple-darwin.tar.gz";
      hash = "sha256-RCHuPqtaIrO2f/6bQqMD5TNZuZUf3zGfjJWHw2uvSxc=";
    };
    x86_64-linux = fetchurl {
      url = "https://github.com/atusy/kakehashi/releases/download/v${version}/kakehashi-v${version}-x86_64-unknown-linux-gnu.tar.gz";
      hash = "sha256-R9QLFm85h0QqnGJP+j1QU3t7e5SiOmfNZjhX8y2mPtA=";
    };
    aarch64-linux = fetchurl {
      url = "https://github.com/atusy/kakehashi/releases/download/v${version}/kakehashi-v${version}-aarch64-unknown-linux-gnu.tar.gz";
      hash = "sha256-xoUOspVDg4A4b3EcqFHtmnRzEOPmdz08YLNceU6brzQ=";
    };
  };
in
stdenvNoCC.mkDerivation rec {
  pname = "kakehashi-bin";
  inherit version;
  src = sources.${stdenvNoCC.hostPlatform.system};

  sourceRoot = ".";

  nativeBuildInputs = [
    versionCheckHook
  ]
  ++ lib.optionals stdenvNoCC.hostPlatform.isLinux [ autoPatchelfHook ];

  buildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [ libgcc ];

  doInstallCheck = true;
  preVersionCheck = ''
    version="''${version#v}"
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    install -Dm755 kakehashi $out/bin/kakehashi
    runHook postInstall
  '';

  passthru = {
    aarch64DarwinSrc = sources.aarch64-darwin;
    x86_64LinuxSrc = sources.x86_64-linux;
    aarch64LinuxSrc = sources.aarch64-linux;
    updateScript = nix-update-script {
      extraArgs = [
        "--version-regex=v(.*)"
        "--custom-dep=aarch64DarwinSrc"
        "--custom-dep=x86_64LinuxSrc"
        "--custom-dep=aarch64LinuxSrc"
      ];
    };
  };

  meta = {
    description = "kakehashi - A Tree-sitter Language Server";
    homepage = "https://github.com/atusy/kakehashi";
    license = lib.licenses.mit;
    changelog = "https://github.com/atusy/kakehashi/releases/tag/v${version}";
    mainProgram = "kakehashi";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
  };
}
