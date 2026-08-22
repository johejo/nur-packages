{
  lib,
  stdenvNoCC,
  nodejs,
  fetchFromGitHub,
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

  nativeBuildInputs = [ nodejs ];

  installPhase = ''
    runHook preInstall
    install -Dm755 json2table.js $out/bin/json2table
    runHook postInstall
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
