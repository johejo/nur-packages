{
  lib,
  stdenvNoCC,
  fetchurl,
  cpio,
  gzip,
  makeWrapper,
  nix-update-script,
  versionCheckHook,
  xar,
}:

stdenvNoCC.mkDerivation rec {
  pname = "container-bin";
  version = "1.3.1";

  src = fetchurl {
    url = "https://github.com/apple/container/releases/download/${version}/container-${version}-installer-signed.pkg";
    hash = "sha256-p8G515J9MIdfL2x70dDLBsLapspXzp6QpRROiY/fVKg=";
  };

  nativeBuildInputs = [
    cpio
    gzip
    makeWrapper
    versionCheckHook
    xar
  ];

  dontPatchShebangs = true;
  dontStrip = true;

  unpackPhase = ''
    runHook preUnpack

    xar -xf "$src"
    mkdir source
    cd source
    gzip -dc ../Payload | cpio --extract --make-directories

    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    install -Dm755 bin/container "$out/bin/container"
    install -Dm755 bin/container-apiserver "$out/bin/container-apiserver"
    mkdir -p "$out/libexec"
    cp -R libexec/container "$out/libexec/container"
    wrapProgram "$out/bin/container" \
      --set CONTAINER_INSTALL_ROOT "$out"

    runHook postInstall
  '';

  doInstallCheck = true;

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Tool for creating and running Linux containers using lightweight virtual machines on macOS";
    homepage = "https://github.com/apple/container";
    changelog = "https://github.com/apple/container/releases/tag/${version}";
    license = lib.licenses.asl20;
    mainProgram = "container";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "aarch64-darwin" ];
  };
}
