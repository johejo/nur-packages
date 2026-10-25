{
  lib,
  stdenvNoCC,
  fetchurl,
  nix-update-script,
  autoPatchelfHook,
  gcc,
}:

let
  version = "2.0.0";
  sources = {
    aarch64-darwin = fetchurl {
      url = "https://install.duckdb.org/v${version}/duckdb-cli-osx-universal.tar.gz";
      hash = "sha256-io9n58f30TkvpjujlxlIOROS/iol/KY+cAjjPFC+tMI=";
    };
    x86_64-linux = fetchurl {
      url = "https://install.duckdb.org/v${version}/duckdb-cli-linux-amd64.tar.gz";
      hash = "sha256-xlByBrr3eTxgE9vYI2hGmkXyDcDhem+S8gRgL2Uu0rw=";
    };
    aarch64-linux = fetchurl {
      url = "https://install.duckdb.org/v${version}/duckdb-cli-linux-arm64.tar.gz";
      hash = "sha256-hZ4YddKpUV+7S/iHEGFDehSvgjINpox1PwlMS3djSP4=";
    };
  };
in
stdenvNoCC.mkDerivation {
  pname = "duckdb-bin";
  inherit version;
  src = sources.${stdenvNoCC.hostPlatform.system};

  nativeBuildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [ autoPatchelfHook ];

  buildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [ gcc.cc.lib ];

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    install -Dm755 duckdb $out/bin/duckdb
    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    $out/bin/duckdb --version | grep -F "v${version}"
  '';

  passthru = {
    aarch64DarwinSrc = sources.aarch64-darwin;
    x86_64LinuxSrc = sources.x86_64-linux;
    aarch64LinuxSrc = sources.aarch64-linux;
    updateScript = nix-update-script {
      extraArgs = [
        "--url=https://github.com/duckdb/duckdb"
        "--custom-dep=aarch64DarwinSrc"
        "--custom-dep=x86_64LinuxSrc"
        "--custom-dep=aarch64LinuxSrc"
      ];
    };
  };

  meta = {
    description = "DuckDB CLI binary distribution";
    homepage = "https://duckdb.org/install";
    license = lib.licenses.mit;
    changelog = "https://github.com/duckdb/duckdb/releases/tag/v${version}";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    mainProgram = "duckdb";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
  };
}
