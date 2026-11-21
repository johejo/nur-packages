{
  lib,
  stdenvNoCC,
  fetchurl,
  nix-update-script,
  autoPatchelfHook,
  gcc,
}:

let
  version = "2.0.1";
  sources = {
    aarch64-darwin = fetchurl {
      url = "https://install.duckdb.org/v${version}/duckdb-cli-osx-universal.tar.gz";
      hash = "sha256-nW6geejDtWmPVZ/GTn5eQ90hpR6KYYspsY3kcWKZykA=";
    };
    x86_64-linux = fetchurl {
      url = "https://install.duckdb.org/v${version}/duckdb-cli-linux-amd64.tar.gz";
      hash = "sha256-tnYmi+TTnk5BqQRELJeWyZFOZFzAhcdQXwSPLJkrXso=";
    };
    aarch64-linux = fetchurl {
      url = "https://install.duckdb.org/v${version}/duckdb-cli-linux-arm64.tar.gz";
      hash = "sha256-hON4kfzEXIh+MCIPUaSRSZXNgXQTnof479MRrIPJVqc=";
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

  # Preserve ELF section ordering to avoid a startup crash after patching.
  patchelfFlags = [ "--no-sort" ];

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
