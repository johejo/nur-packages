{ stdenvNoCC, source }:

stdenvNoCC.mkDerivation rec {
  inherit (source) pname version src;
  dontUnpack = true;
  installPhase = ''
    mkdir -p $out/lib
    cp ${src} $out/lib/gitbucket.war
  '';
}
