{
  lib,
  bun,
  buildNpmPackage,
  makeWrapper,
  source,
  ...
}:

buildNpmPackage {
  inherit (source) pname version src;

  npmDepsHash = "sha256-aMqFdXWiPW4olMx93eQZqIMzhyiWpBnGFv44Rg00fUg=";

  nativeBuildInputs = [
    makeWrapper
  ];

  dontNpmBuild = true;

  postFixup = ''
    for bin in confluence confluence-cli; do
      rm "$out/bin/$bin"
      makeWrapper ${bun}/bin/bun "$out/bin/$bin" \
        --add-flags "$out/lib/node_modules/confluence-cli/bin/index.js"
    done
  '';

  meta = {
    description = "A command-line interface for Atlassian Confluence with page creation and editing capabilities";
    homepage = "https://github.com/pchuri/confluence-cli";
    license = lib.licenses.mit;
    mainProgram = "confluence";
  };
}
