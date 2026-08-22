{
  lib,
  stdenvNoCC,
  deno,
  fetchFromGitHub,
  makeWrapper,
  nix-update-script,
  ...
}:

stdenvNoCC.mkDerivation {
  pname = "json2table";
  version = "0-unstable-2026-04-09";
  src = fetchFromGitHub {
    owner = "johejo";
    repo = "json2table";
    rev = "45e65ae2200fc38be28439b3397e93a78aa1f97c";
    hash = "sha256-WQLtjLsLr1U1rL3xEfkyeKiCUadibD2Hi112bIGmzQs=";
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall
    install -Dm444 json2table.js $out/libexec/json2table/json2table.js
    makeWrapper ${lib.getExe deno} $out/bin/json2table \
      --set DENO_NO_UPDATE_CHECK 1 \
      --add-flags run \
      --add-flags --no-config \
      --add-flags --cached-only \
      --add-flags $out/libexec/json2table/json2table.js
    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    $out/bin/json2table --help | grep -F "Usage: json2table"
    printf '%s\n' '[{"name":"John","age":30}]' | $out/bin/json2table > table
    grep -F "John" table
    grep -F "30" table
    runHook postInstallCheck
  '';

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch=main" ]; };

  meta = {
    description = "Convert JSON from stdin to a table";
    homepage = "https://github.com/johejo/json2table";
    license = lib.licenses.mit;
    mainProgram = "json2table";
    platforms = lib.platforms.unix;
  };
}
