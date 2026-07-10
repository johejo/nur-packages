{
  lib,
  stdenvNoCC,
  source,
}:

stdenvNoCC.mkDerivation rec {
  inherit (source) pname version src;
  dontUnpack = true;
  installPhase = ''
    mkdir -p $out/lib
    cp ${src} $out/lib/gitbucket.war
  '';
  meta = {
    description = "A Git platform powered by Scala with easy installation, high extensibility & GitHub API compatibility";
    homepage = "https://github.com/gitbucket/gitbucket";
    license = lib.licenses.asl20;
    changelog = "https://github.com/gitbucket/gitbucket/releases/tag/${version}";
  };
}
