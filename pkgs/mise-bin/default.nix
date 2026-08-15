{
  lib,
  stdenv,
  source,
  autoPatchelfHook,
  libgcc,
  versionCheckHook,
  ...
}:

stdenv.mkDerivation rec {
  pname = "mise-bin";
  inherit (source) version src;

  sourceRoot = ".";

  nativeBuildInputs = [
    versionCheckHook
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [ libgcc ];

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

  meta = {
    description = "Dev tools, env vars, task runner";
    homepage = "https://github.com/jdx/mise";
    license = lib.licenses.mit;
    changelog = "https://github.com/jdx/mise/releases/tag/${version}";
    mainProgram = "mise";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
  };
}
