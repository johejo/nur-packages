{
  lib,
  unzip,
  stdenvNoCC,
  autoPatchelfHook,
  cctools,
  fixDarwinDylibNames,
  gcc,
  source,
}:

stdenvNoCC.mkDerivation rec {
  pname = "libduckdb-bin";
  inherit (source) version src;

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

  meta = {
    description = "libduckdb binary distribution";
    homepage = "https://duckdb.org/install";
    license = lib.licenses.mit;
    changelog = "https://github.com/duckdb/duckdb/releases/tag/${version}";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
  };
}
