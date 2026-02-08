{
  lib,
  stdenv,
  source,
  ...
}:

stdenv.mkDerivation {
  inherit (source) pname src version;
  sourceRoot = "source/zlib";

  NIX_CFLAGS_COMPILE = lib.optionals stdenv.isLinux [
    "-Wno-old-style-definition"
    "-include stdint.h"
  ];

  configureFlags = [ "--shared" ];

  makeFlags = lib.optionals stdenv.isDarwin [
    "SHAREDLIB=libz.dylib"
    "SHAREDLIBM=libz.1.dylib"
    "SHAREDLIBV=libz.1.2.11.dylib"
  ];

  postInstall = lib.optionalString stdenv.isDarwin ''
    install_name_tool -id \
      $out/lib/libz.1.dylib \
      $out/lib/libz.1.2.11.dylib
  '';

  enableParallelBuilding = true;

  meta = {
    description = "Apple Open Source Distribution of zlib";
    homepage = "https://github.com/apple-oss-distributions/zlib";
    license = lib.licenses.zlib;
  };
}
