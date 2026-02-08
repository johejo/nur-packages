{
  lib,
  stdenv,
  source,
  ...
}:

stdenv.mkDerivation {
  inherit (source) pname version src;
  sourceRoot = "source/db";

  preConfigure = ''
    cd build_unix
    configureScript=../dist/configure
  '';

  enableParallelBuilding = true;

  meta = {
    description = "Apple Open Source Distribution of Berkeley DB";
    homepage = "https://github.com/apple-oss-distributions/BerkeleyDB";
    license = lib.licenses.sleepycat;
  };
}
