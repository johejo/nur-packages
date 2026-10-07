{ lib, pkgs, nix-update-script, versionCheckHook }:

pkgs.apfel-llm.overrideAttrs (old: rec {
  version = "1.16.0";
  src = pkgs.fetchurl {
    url = "https://github.com/Arthur-Ficial/apfel/releases/download/v${version}/apfel-${version}-arm64-macos.tar.gz";
    hash = "sha256-K6B7mcjCOP1KV91yGrcwnqBy/ENLULZTBpwvhCiDilc=";
  };

  preVersionCheck = ''
    version="v${version}"
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 apfel $out/bin/apfel
    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = old.meta // {
    changelog = "https://github.com/Arthur-Ficial/apfel/releases/tag/v${version}";
  };
})