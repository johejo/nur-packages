{
  buildNpmPackage,
  source,
  ...
}:

buildNpmPackage {
  inherit (source) pname version src;

  npmDepsHash = "sha256-QCKtFHdxDILIifsfkQHAZh7/1jfsOE9pjrPGsdjdRBg=";

  postPatch = ''
    cp npm-shrinkwrap.json package-lock.json
  '';

  dontNpmBuild = true;

  meta = {
    mainProgram = "confluence";
  };
}
