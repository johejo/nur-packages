{
  lib,
  stdenv,
  perl,
  libressl,
  nghttp2,
  zlib,
  source,
  ...
}:

stdenv.mkDerivation {
  inherit (source) pname src version;
  sourceRoot = "source/curl";

  nativeBuildInputs = [ perl ];
  buildInputs = [
    libressl
    zlib
    nghttp2
  ];

  configureFlags = [
    "--with-openssl"
    "--with-zlib"
    "--with-nghttp2"
  ]
  ++ lib.optionals stdenv.isDarwin [ "--with-secure-transport" ];

  postPatch = ''
    patchShebangs scripts
  '';

  enableParallelBuilding = true;

  meta = {
    description = "Apple Open Source Distribution of curl";
    homepage = "https://github.com/apple-oss-distributions/curl";
    license = lib.licenses.curl;
  };
}
