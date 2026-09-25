{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
  ...
}:

buildGoModule {
  pname = "tailctl";
  version = "0-unstable-2026-09-24";
  src = fetchFromGitHub {
    owner = "johejo";
    repo = "tailctl";
    rev = "8d07046d827067c522a6e28b5b43e1c75cbd8ae5";
    hash = "sha256-PYtybNyj4+zrSpP9PDoQVR/nn/25jEazboikZRF+h/s=";
  };
  vendorHash = "sha256-nNwjOy1qtO5MdBYOsOoqPYZuIiOcTuUN2Z5ZkFKKq+s=";
  subPackages = [ "cmd/tailctl" ];

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch=main" ]; };

  meta = {
    description = "Command-line client for the Tailscale API";
    homepage = "https://github.com/johejo/tailctl";
    license = lib.licenses.mit;
    mainProgram = "tailctl";
  };
}
