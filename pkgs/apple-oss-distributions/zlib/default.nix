{
  lib,
  stdenv,
  source,
  ...
}:

stdenv.mkDerivation {
  inherit (source) pname src version;
  sourceRoot = "source/zlib";
}
