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
  version = "2026.10.11";
  sources = {
    aarch64-darwin = fetchurl {
      url = "https://github.com/jdx/mise/releases/download/v${version}/mise-v${version}-macos-arm64.tar.gz";
      hash = "sha256-ZFkuKXhFnZG53GkDUsl9WajCsyf1hv0gFGj6Vq/mYxE=";
    };
    x86_64-linux = fetchurl {
      url = "https://github.com/jdx/mise/releases/download/v${version}/mise-v${version}-linux-x64.tar.gz";
      hash = "sha256-p9Cq09Z4LUJnX+Cicys5v8NW9s8rVUQ3+ExZeBSi/YU=";
    };
    aarch64-linux = fetchurl {
      url = "https://github.com/jdx/mise/releases/download/v${version}/mise-v${version}-linux-arm64.tar.gz";
      hash = "sha256-dTTVFElUSeJnmXQQWDgzCA7QuZoAU/OyahBpF5Sll7U=";
    };
  };
in
stdenvNoCC.mkDerivation rec {
  pname = "mise-bin";
  inherit version;
  src = sources.${stdenvNoCC.hostPlatform.system};

  sourceRoot = ".";

  nativeBuildInputs = [
    versionCheckHook
  ]
  ++ lib.optionals stdenvNoCC.hostPlatform.isLinux [ autoPatchelfHook ];

  buildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [ libgcc ];

  dontStrip = true;

  doInstallCheck = true;
  preVersionCheck = ''
    version="''${version#v}"
    export MISE_OFFLINE=1
    export XDG_CACHE_HOME="$TMPDIR/xdg-cache"
    export XDG_CONFIG_HOME="$TMPDIR/xdg-config"
    export XDG_DATA_HOME="$TMPDIR/xdg-data"
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r mise/* $out/
    runHook postInstall
  '';

  passthru = {
    aarch64DarwinSrc = sources.aarch64-darwin;
    x86_64LinuxSrc = sources.x86_64-linux;
    aarch64LinuxSrc = sources.aarch64-linux;
    updateScript = nix-update-script {
      extraArgs = [
        "--version-regex=v([0-9].*)"
        "--custom-dep=aarch64DarwinSrc"
        "--custom-dep=x86_64LinuxSrc"
        "--custom-dep=aarch64LinuxSrc"
      ];
    };
  };

  meta = {
    description = "Dev tools, env vars, task runner";
    homepage = "https://github.com/jdx/mise";
    license = lib.licenses.mit;
    changelog = "https://github.com/jdx/mise/releases/tag/v${version}";
    mainProgram = "mise";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
  };
}
