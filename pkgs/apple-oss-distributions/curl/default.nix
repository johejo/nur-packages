{
  lib,
  stdenv,
  perl,
  libressl,
  source,
  ...
}:

stdenv.mkDerivation {
  inherit (source) pname src version;
  sourceRoot = "source/curl";
  nativeBuildInputs = [ perl ];
  buildInputs = [ libressl ];
  configureFlags = [ "--with-openssl" ];
  postPatch = ''
    patchShebangs scripts
  '';
  meta = {
    description = "Apple Open Source Distribution of curl";
    homepage = "https://github.com/apple-oss-distributions/curl";
    license = lib.licenses.curl;
  };
}
