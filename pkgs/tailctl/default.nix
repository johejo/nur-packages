{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
  ...
}:

buildGoModule {
  pname = "tailctl";
  version = "0-unstable-2026-09-23";
  src = fetchFromGitHub {
    owner = "johejo";
    repo = "tailctl";
    rev = "66b513ecb57c8d8369835d746c223ee8922cb674";
    hash = "sha256-DWmVPeCujIYfUeCC682nAfUmt3CTkcqbPPZGNPgUbhc=";
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
