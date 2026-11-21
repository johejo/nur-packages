{
  lib,
  stdenvNoCC,
  fetchurl,
  nix-update-script,
  autoPatchelfHook,
  cctools,
  fixDarwinDylibNames,
  darwin,
  gcc,
}:

let
  version = "2.0.1";
  sources = {
    aarch64-darwin = fetchurl {
      url = "https://install.duckdb.org/v${version}/duckdb-shared-libs-osx-universal.tar.gz";
      hash = "sha256-mkvloqMa1buMkr838Y1ZucEKebOS14SMq9brLgWDdEk=";
    };
    x86_64-linux = fetchurl {
      url = "https://install.duckdb.org/v${version}/duckdb-shared-libs-linux-amd64.tar.gz";
      hash = "sha256-4lUCYS/tUzokO2HyOipXTarQMOfoiQYiKl8Ksw0Gdp4=";
    };
    aarch64-linux = fetchurl {
      url = "https://install.duckdb.org/v${version}/duckdb-shared-libs-linux-arm64.tar.gz";
      hash = "sha256-gR6LTQIm9eUx9YOq3HmAcP+zOzUOOCO+VjouvrLGhZM=";
    };
  };
in
stdenvNoCC.mkDerivation rec {
  pname = "libduckdb-bin";
  inherit version;
  src = sources.${stdenvNoCC.hostPlatform.system};

  nativeBuildInputs =
    lib.optionals stdenvNoCC.hostPlatform.isLinux [ autoPatchelfHook ]
    ++ lib.optionals stdenvNoCC.hostPlatform.isDarwin [
      cctools
      fixDarwinDylibNames
      darwin.autoSignDarwinBinariesHook
    ];

  buildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [ gcc.cc.lib ];

  sourceRoot = ".";

  installPhase = ''
    mkdir -p $out/include
    cp *.h $out/include/
    mkdir -p $out/lib
  ''
  + lib.optionalString stdenvNoCC.hostPlatform.isLinux ''
    cp libduckdb.so $out/lib/libduckdb.so
  ''
  + lib.optionalString stdenvNoCC.hostPlatform.isDarwin ''
    cp libduckdb.dylib $out/lib/libduckdb.dylib
  ''
  + ''
    runHook postInstall
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
    description = "libduckdb binary distribution";
    homepage = "https://duckdb.org/install";
    license = lib.licenses.mit;
    changelog = "https://github.com/duckdb/duckdb/releases/tag/v${version}";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
  };
}
