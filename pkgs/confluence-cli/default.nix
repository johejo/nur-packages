{
  bun,
  buildNpmPackage,
  makeWrapper,
  source,
  ...
}:

buildNpmPackage {
  inherit (source) pname version src;

  npmDepsHash = "sha256-8oxlUVSHv07Hm2COC0mR+tmmjqPvY9xcalBYooLKO7k=";

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
    mainProgram = "confluence";
  };
}
