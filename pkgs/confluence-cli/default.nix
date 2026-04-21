{
  bun,
  buildNpmPackage,
  makeWrapper,
  source,
  ...
}:

buildNpmPackage {
  inherit (source) pname version src;

  npmDepsHash = "sha256-q8bCduyDUC/2ez5ft+pEJQIvEmSuXaEwNbAyl0pFB50=";

  nativeBuildInputs = [
    makeWrapper
  ];

  postPatch = ''
    cp npm-shrinkwrap.json package-lock.json
  '';

  dontNpmBuild = true;

  postFixup = ''
    for bin in confluence confluence-cli; do
      rm "$out/bin/$bin"
      makeWrapper ${bun}/bin/bun "$out/bin/$bin" \
        --add-flags "$out/lib/node_modules/confluence-cli/bin/index.js"
    done
  '';

  meta = {
    mainProgram = "confluence";
  };
}
