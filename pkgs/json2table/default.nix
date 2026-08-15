{
  lib,
  stdenvNoCC,
  nodejs,
  source,
  ...
}:

stdenvNoCC.mkDerivation {
  inherit (source) pname version src;

  nativeBuildInputs = [ nodejs ];

  installPhase = ''
    runHook preInstall
    install -Dm755 json2table.js $out/bin/json2table
    runHook postInstall
  '';

  meta = {
    description = "Convert JSON from stdin to a table";
    homepage = "https://github.com/johejo/json2table";
    license = lib.licenses.mit;
    mainProgram = "json2table";
    platforms = lib.platforms.unix;
  };
}
