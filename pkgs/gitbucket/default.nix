{
  lib,
  stdenvNoCC,
  fetchurl,
  nix-update-script,
}:

stdenvNoCC.mkDerivation rec {
  pname = "gitbucket";
  version = "4.47.1";
  src = fetchurl {
    url = "https://github.com/gitbucket/gitbucket/releases/download/${version}/gitbucket.war";
    hash = "sha256-yrstcyzLoR2OSM2beopNzDdN75mLvPA8eb2XraF7DBs=";
  };
  dontUnpack = true;
  installPhase = ''
    mkdir -p $out/lib
    cp ${src} $out/lib/gitbucket.war
  '';
  passthru.updateScript = nix-update-script { };
  meta = {
    description = "A Git platform powered by Scala with easy installation, high extensibility & GitHub API compatibility";
    homepage = "https://github.com/gitbucket/gitbucket";
    license = lib.licenses.asl20;
    changelog = "https://github.com/gitbucket/gitbucket/releases/tag/${version}";
  };
}
