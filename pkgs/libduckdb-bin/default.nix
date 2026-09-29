{
  lib,
  unzip,
  stdenvNoCC,
  fetchurl,
  nix-update-script,
  autoPatchelfHook,
  cctools,
  fixDarwinDylibNames,
  gcc,
}:

let
  version = "1.5.6";
  sources = {
    aarch64-darwin = fetchurl {
      url = "https://install.duckdb.org/v${version}/libduckdb-osx-universal.zip";
      hash = "sha256-4LwAfZsAlMCXCsGEeoYB0QqtB8vSkQzlhuyBD3e2ONY=";
    };
    x86_64-linux = fetchurl {
      url = "https://install.duckdb.org/v${version}/libduckdb-linux-amd64.zip";
      hash = "sha256-uEUAX1Eyp9gYAFfDXhSnYmYyJYeC+HGpCGGxnBwDhBs=";
    };
    aarch64-linux = fetchurl {
      url = "https://install.duckdb.org/v${version}/libduckdb-linux-arm64.zip";
      hash = "sha256-ty7Z8FAD9enSAV986tpkFrN32d0zFpzd48njOJeFbu4=";
    };
  };
in
stdenvNoCC.mkDerivation rec {
  pname = "libduckdb-bin";
  inherit version;
  src = sources.${stdenvNoCC.hostPlatform.system};

  nativeBuildInputs = [
    unzip
  ]
  ++ lib.optionals stdenvNoCC.hostPlatform.isLinux [ autoPatchelfHook ]
  ++ lib.optionals stdenvNoCC.hostPlatform.isDarwin [
    cctools
    fixDarwinDylibNames
  ];

  buildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [ gcc.cc.lib ];

  unpackPhase = ''
    unzip $src
  '';

  installPhase = ''
    mkdir -p $out/include
    cp duckdb.* $out/include/
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
