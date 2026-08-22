{
  lib,
  stdenvNoCC,
  fetchurl,
  nix-update-script,
  versionCheckHook,
  ...
}:

let
  version = "0.22.0";
  sources = {
    aarch64-darwin = fetchurl {
      url = "https://github.com/agavra/tuicr/releases/download/v${version}/tuicr-${version}-aarch64-apple-darwin.tar.gz";
      hash = "sha256-zQ21zQITSpAIEiJo3PAV0ZDRr1GiM1XTkXA5436TiaI=";
    };
    x86_64-linux = fetchurl {
      url = "https://github.com/agavra/tuicr/releases/download/v${version}/tuicr-${version}-x86_64-unknown-linux-musl.tar.gz";
      hash = "sha256-+qIhvnW+TL8XXzjR5UfjvUShEI7+6LnRBGUqsHTVuB8=";
    };
    aarch64-linux = fetchurl {
      url = "https://github.com/agavra/tuicr/releases/download/v${version}/tuicr-${version}-aarch64-unknown-linux-musl.tar.gz";
      hash = "sha256-nj8lj+t/M0ZO9jN9RRNBjtAGNpFFVnBIA5XrMs4D8fY=";
    };
  };
in
stdenvNoCC.mkDerivation rec {
  pname = "tuicr-bin";
  inherit version;
  src = sources.${stdenvNoCC.hostPlatform.system};

  sourceRoot = ".";

  nativeInstallCheckInputs = [ versionCheckHook ];

  doInstallCheck = true;
  preVersionCheck = ''
    version="''${version#v}"
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 tuicr $out/bin/tuicr
    runHook postInstall
  '';

  passthru = {
    aarch64DarwinSrc = sources.aarch64-darwin;
    x86_64LinuxSrc = sources.x86_64-linux;
    aarch64LinuxSrc = sources.aarch64-linux;
    updateScript = nix-update-script {
      extraArgs = [
        "--custom-dep=aarch64DarwinSrc"
        "--custom-dep=x86_64LinuxSrc"
        "--custom-dep=aarch64LinuxSrc"
      ];
    };
  };

  meta = {
    description = "Review AI-generated diffs like a GitHub pull request, right from your terminal";
    homepage = "https://github.com/agavra/tuicr";
    changelog = "https://github.com/agavra/tuicr/releases/tag/v${version}";
    license = lib.licenses.mit;
    mainProgram = "tuicr";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
  };
}
