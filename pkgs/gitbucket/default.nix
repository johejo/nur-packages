{
  lib,
  stdenvNoCC,
  fetchurl,
  nix-update-script,
}:

stdenvNoCC.mkDerivation rec {
  pname = "gitbucket";
  version = "4.47.0";
  src = fetchurl {
    url = "https://github.com/gitbucket/gitbucket/releases/download/${version}/gitbucket.war";
    hash = "sha256-fdXIZOFeq5zWSWlM7/VBxdKwU3MmGc3J6lbFv2PSdsI=";
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
