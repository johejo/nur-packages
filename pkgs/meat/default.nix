{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
  gitMinimal,
  makeWrapper,
  ...
}:

buildGoModule {
  pname = "meat";
  version = "0-unstable-2026-08-03";
  src = fetchFromGitHub {
    owner = "boldsoftware";
    repo = "meat";
    rev = "f39f41dfe7b5b37a12b35fdfbaecc7e779855bd3";
    hash = "sha256-fj04sdMiwPxh4F+kBpF5c+YYeKnKCDD9dsIgwAGPoK4=";
  };

  subPackages = [ "cmd/meat" ];
  vendorHash = null;

  nativeBuildInputs = [
    gitMinimal
    makeWrapper
  ];

  ldflags = [
    "-s"
    "-w"
  ];

  preCheck = ''
    go test ./meat
  '';

  postInstall = ''
    wrapProgram $out/bin/meat \
      --prefix PATH : ${lib.makeBinPath [ gitMinimal ]}
  '';

  doInstallCheck = true;
  postInstallCheck = ''
    $out/bin/meat -h
  '';

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch=main" ]; };

  meta = {
    description = "Abridge a code diff into a reading diff";
    homepage = "https://github.com/boldsoftware/meat";
    license = lib.licenses.asl20;
    mainProgram = "meat";
    platforms = lib.platforms.unix;
  };
}
