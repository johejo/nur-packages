{
  lib,
  buildGoModule,
  gitMinimal,
  makeWrapper,
  source,
  ...
}:

buildGoModule {
  inherit (source) pname version src;

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

  meta = {
    description = "Abridge a code diff into a reading diff";
    homepage = "https://github.com/boldsoftware/meat";
    license = lib.licenses.asl20;
    mainProgram = "meat";
    platforms = lib.platforms.unix;
  };
}
