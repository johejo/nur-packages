{
  lib,
  stdenv,
  source,
  ...
}:

stdenv.mkDerivation {
  inherit (source) pname version src;
  sourceRoot = "source/db";

  NIX_CFLAGS_COMPILE = lib.optionals stdenv.isLinux [ "-Wno-old-style-definition" ];

  preConfigure = ''
    cd build_unix
    configureScript=../dist/configure
  '';

  configureFlags = lib.optionals stdenv.isLinux [
    "--enable-posixmutexes"
    "db_cv_mutex=POSIX/pthreads"
  ];

  enableParallelBuilding = true;

  meta = {
    description = "Apple Open Source Distribution of Berkeley DB";
    homepage = "https://github.com/apple-oss-distributions/BerkeleyDB";
    license = lib.licenses.sleepycat;
  };
}
