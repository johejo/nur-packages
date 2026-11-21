{
  lib,
  stdenvNoCC,
  curl,
  fetchurl,
  gnused,
  nix-update,
  versionCheckHook,
  writeShellApplication,
  ...
}:

let
  version = "1.85.0";
  majorVersion = lib.versions.major version;
  sources = {
    aarch64-darwin = fetchurl {
      url = "https://downloads.wiz.io/v${majorVersion}/wizcli/${version}/wizcli-darwin-arm64";
      hash = "sha256-xS1Zrct3AqaShs99IZxRLEQsHVYM3G/bJNDDW3+5MZc=";
    };
    x86_64-linux = fetchurl {
      url = "https://downloads.wiz.io/v${majorVersion}/wizcli/${version}/wizcli-linux-amd64";
      hash = "sha256-0cyw0GGfbWobVGvlA4XANhmK2daw7embk/o4n76WZNs=";
    };
    aarch64-linux = fetchurl {
      url = "https://downloads.wiz.io/v${majorVersion}/wizcli/${version}/wizcli-linux-arm64";
      hash = "sha256-79WSbg6IiYPnMeDZzQ14z8e7iZinjc0nT9g1tarDtB8=";
    };
  };
in
stdenvNoCC.mkDerivation {
  pname = "wizcli-bin";
  inherit version;
  src = sources.${stdenvNoCC.hostPlatform.system};

  dontUnpack = true;

  nativeInstallCheckInputs = [ versionCheckHook ];

  doInstallCheck = true;
  versionCheckProgramArg = "version";

  preInstallCheck = ''
    export HOME=$TMPDIR
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/wizcli
    runHook postInstall
  '';

  passthru = {
    aarch64DarwinSrc = sources.aarch64-darwin;
    x86_64LinuxSrc = sources.x86_64-linux;
    aarch64LinuxSrc = sources.aarch64-linux;
    updateScript = [
      (lib.getExe (writeShellApplication {
        name = "update-wizcli-bin";
        runtimeInputs = [
          curl
          gnused
          nix-update
        ];
        text = ''
          version="$({
            curl -sSf https://downloads.wiz.io/v${majorVersion}/wizcli/latest/wizcli-version
          } | sed -n 's/^cli: *"\([0-9][0-9.]*\).*$/\1/p' | head -n1)"
          # Refresh hashes even when a previous attempt already set the version.
          for targetVersion in "$version" skip; do
            nix-update wizcli-bin --flake \
              --version="$targetVersion" \
              --custom-dep=aarch64DarwinSrc \
              --custom-dep=x86_64LinuxSrc \
              --custom-dep=aarch64LinuxSrc
          done
        '';
      }))
    ];
  };

  meta = {
    description = "CLI for interacting with the Wiz platform";
    homepage = "https://www.wiz.io/";
    license = lib.licenses.unfree;
    mainProgram = "wizcli";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
  };
}
