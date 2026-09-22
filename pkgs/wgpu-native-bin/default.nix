{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
  autoPatchelfHook,
  cctools,
  fixDarwinDylibNames,
  gcc,
  vulkan-loader,
  nix-update-script,
}:

let
  version = "29.0.1.1";
  sources = {
    aarch64-darwin = fetchurl {
      url = "https://github.com/gfx-rs/wgpu-native/releases/download/v${version}/wgpu-macos-aarch64-release.zip";
      hash = "sha256-pXl6N7Gt9yC81dz/spHtu9W3sUvgo4dMKOY5OmVaej4=";
    };
    x86_64-linux = fetchurl {
      url = "https://github.com/gfx-rs/wgpu-native/releases/download/v${version}/wgpu-linux-x86_64-release.zip";
      hash = "sha256-laTZDAcQBamNA+qzSL6qawfhbrANHc25+DSPdeuX7Fo=";
    };
    aarch64-linux = fetchurl {
      url = "https://github.com/gfx-rs/wgpu-native/releases/download/v${version}/wgpu-linux-aarch64-release.zip";
      hash = "sha256-AV/N8duuguYUp4PMOAF+U5muCSeoif6bacm2ZLxhtHo=";
    };
  };
in
stdenvNoCC.mkDerivation {
  pname = "wgpu-native-bin";
  inherit version;
  src = sources.${stdenvNoCC.hostPlatform.system};

  outputs = [
    "out"
    "dev"
  ];

  nativeBuildInputs = [
    unzip
  ]
  ++ lib.optional stdenvNoCC.hostPlatform.isLinux autoPatchelfHook
  ++ lib.optionals stdenvNoCC.hostPlatform.isDarwin [
    cctools
    fixDarwinDylibNames
  ];

  buildInputs = lib.optional stdenvNoCC.hostPlatform.isLinux gcc.cc.lib;

  # wgpu loads Vulkan with dlopen rather than linking against it.
  appendRunpaths = lib.optional stdenvNoCC.hostPlatform.isLinux "${lib.getLib vulkan-loader}/lib";

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    install -Dm644 include/webgpu/*.h -t "$dev/include/webgpu"
    install -Dm755 lib/libwgpu_native${stdenvNoCC.hostPlatform.extensions.sharedLibrary} -t "$out/lib"

    runHook postInstall
  '';

  passthru = {
    aarch64DarwinSrc = sources.aarch64-darwin;
    x86_64LinuxSrc = sources.x86_64-linux;
    aarch64LinuxSrc = sources.aarch64-linux;
    updateScript = nix-update-script {
      extraArgs = [
        "--url=https://github.com/gfx-rs/wgpu-native"
        "--custom-dep=aarch64DarwinSrc"
        "--custom-dep=x86_64LinuxSrc"
        "--custom-dep=aarch64LinuxSrc"
      ];
    };
  };

  meta = {
    description = "Native WebGPU implementation based on wgpu-core (binary distribution)";
    homepage = "https://github.com/gfx-rs/wgpu-native";
    changelog = "https://github.com/gfx-rs/wgpu-native/releases/tag/v${version}";
    license = with lib.licenses; [
      mit
      asl20
    ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = builtins.attrNames sources;
  };
}
