{
  lib,
  unzip,
  stdenvNoCC,
  fetchurl,
  nix-update-script,
  autoPatchelfHook,
  gcc,
}:

let
  version = "1.5.6";
  sources = {
    aarch64-darwin = fetchurl {
      url = "https://install.duckdb.org/v${version}/duckdb_cli-osx-universal.zip";
      hash = "sha256-gKgMaHNr196lPosCRH6XWdsMhZbqFWR2ujlsRPVMWBA=";
    };
    x86_64-linux = fetchurl {
      url = "https://install.duckdb.org/v${version}/duckdb_cli-linux-amd64.zip";
      hash = "sha256-bonerB67w27tApHK+LVnsDDHuGrDWZj3GFTiKzxdXi8=";
    };
    aarch64-linux = fetchurl {
      url = "https://install.duckdb.org/v${version}/duckdb_cli-linux-arm64.zip";
      hash = "sha256-xUTpLJt8MfxTwhOYAsq9ji0bKz4/kzEX8xYRI5wUAts=";
    };
  };
in
stdenvNoCC.mkDerivation {
  pname = "duckdb-bin";
  inherit version;
  src = sources.${stdenvNoCC.hostPlatform.system};

  nativeBuildInputs = [
    unzip
  ]
  ++ lib.optionals stdenvNoCC.hostPlatform.isLinux [ autoPatchelfHook ];

  buildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [ gcc.cc.lib ];

  unpackPhase = ''
    unzip $src
  '';

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
