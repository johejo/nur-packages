{
  lib,
  stdenv,
  zlib,
  libressl,
  source,
  ...
}:

stdenv.mkDerivation {
  inherit (source) pname src version;
  sourceRoot = "source/openssh";

  enableParallelBuilding = true;

  buildInputs = [
    zlib
    libressl
  ];

  postPatch = ''
    substituteInPlace Makefile.in --replace "$(INSTALL) -m 4711" "$(INSTALL) -m 0711"
  ''
  + lib.optionalString stdenv.isDarwin ''
    substituteInPlace ssh.c --replace "#include <si_compare.h>" ""
    substituteInPlace ssh.c --replace "(void)si_destination_compare(&dummy, 0, &dummy, 0, false);" ""
  '';

  meta = {
    description = "Apple Open Source Distribution of OpenSSH";
    homepage = "https://github.com/apple-oss-distributions/OpenSSH";
    license = lib.licenses.bsd2;
  };
}
