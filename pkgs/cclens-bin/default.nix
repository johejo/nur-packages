{
  lib,
  stdenvNoCC,
  fetchurl,
  nix-update-script,
  autoPatchelfHook,
  libgcc,
  ...
}:

let
  version = "0.3.2";
  sources = {
    aarch64-darwin = fetchurl {
      url = "https://github.com/lambdalisue/cclens/releases/download/v${version}/cclens-v${version}-aarch64-apple-darwin.tar.gz";
      hash = "sha256-S06gQjcXpnk2zcp2tfda7HkOv6ZIcmagko0ay2Y5Tto=";
    };
    x86_64-linux = fetchurl {
      url = "https://github.com/lambdalisue/cclens/releases/download/v${version}/cclens-v${version}-x86_64-unknown-linux-gnu.tar.gz";
      hash = "sha256-r8LIvAlgebn6hei6C90hrH8xphEf0xVy+2MGwJvbKuA=";
    };
    aarch64-linux = fetchurl {
      url = "https://github.com/lambdalisue/cclens/releases/download/v${version}/cclens-v${version}-aarch64-unknown-linux-gnu.tar.gz";
      hash = "sha256-chETJScnunPjLz7Ya5tj7U5HSZ43cD0O1nogs53N4vk=";
    };
  };
in
stdenvNoCC.mkDerivation rec {
  pname = "cclens-bin";
  inherit version;
  src = sources.${stdenvNoCC.hostPlatform.system};

  sourceRoot = ".";

  nativeBuildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [ autoPatchelfHook ];

  buildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [ libgcc ];

  doInstallCheck = true;

  installCheckPhase = ''
    runHook preInstallCheck
    $out/bin/cclens --help > /dev/null
    runHook postInstallCheck
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 cclens $out/bin/cclens
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
    description = "Lens onto your Claude Code usage";
    homepage = "https://github.com/lambdalisue/cclens";
    changelog = "https://github.com/lambdalisue/cclens/releases/tag/v${version}";
    mainProgram = "cclens";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
  };
}
