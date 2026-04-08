{
  buildNpmPackage,
  source,
  ...
}:

buildNpmPackage {
  inherit (source) pname version src;

  npmDepsHash = "sha256-fNX5gQIVg20o2ySbvg6wKcykfbHPNTbp2bIQEwAnBSg=";

  postPatch = ''
    cp npm-shrinkwrap.json package-lock.json
  '';

  dontNpmBuild = true;

  meta = {
    mainProgram = "confluence";
  };
}
