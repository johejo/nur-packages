{
  buildNpmPackage,
  source,
  ...
}:

buildNpmPackage {
  inherit (source) pname version src;

  npmDepsHash = "sha256-3D9OBvtJ2Kv7IhTX/vv4+txxBCDL/x4gh+094Tv55FU=";

  postPatch = ''
    cp npm-shrinkwrap.json package-lock.json
  '';

  dontNpmBuild = true;

  meta = {
    mainProgram = "confluence";
  };
}
