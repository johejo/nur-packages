{
  lib,
  stdenv,
  stdenvNoCC,
  fetchurl,
  unzip,
  autoPatchelfHook,
  nix-update-script,
  versionCheckHook,
  ...
}:

let
  version = "0.22.4";
  release = "https://github.com/kiron1/bazel-compile-commands/releases/download/bazel-compile-commands-v${version}";
  sources = {
    aarch64-darwin = fetchurl {
      url = "${release}/bazel-compile-commands_${version}-macos_universal.zip";
      hash = "sha256-YYPLrsXZZn5N74WQ5FWKTo6xBto04s2KFnM/i+zxzk4=";
    };
    x86_64-linux = fetchurl {
      url = "${release}/bazel-compile-commands_${version}-linux_amd64.zip";
      hash = "sha256-uxYq2u+ygqnk8POZ/mIj0dL+N0BRgUjByo9vgdtAA/Y=";
    };
    aarch64-linux = fetchurl {
      url = "${release}/bazel-compile-commands_${version}-linux_arm64.zip";
      hash = "sha256-wa1aWhx6r3nY7+ViAe3gSxgLQDHuRMra/aE3O3UClJg=";
    };
  };
  licenseSrc = fetchurl {
    url = "https://raw.githubusercontent.com/kiron1/bazel-compile-commands/bazel-compile-commands-v${version}/LICENSE.txt";
    hash = "sha256-GTmaCC4dxAirrcN69I6jWjePqoVRh2mMdZg8/qdr/no=";
  };
in
stdenvNoCC.mkDerivation {
  pname = "bazel-compile-commands-bin";
  inherit version;
  src = sources.${stdenvNoCC.hostPlatform.system};

  sourceRoot = ".";

  nativeBuildInputs = [ unzip ] ++ lib.optionals stdenvNoCC.hostPlatform.isLinux [ autoPatchelfHook ];
  buildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [ stdenv.cc.cc.lib ];
  nativeInstallCheckInputs = [ versionCheckHook ];

  installPhase = ''
    runHook preInstall
    install -Dm755 usr/bin/bazel-compile-commands $out/bin/bazel-compile-commands
    install -Dm755 usr/bin/bazel-clangd-wrapper $out/bin/bazel-clangd-wrapper
    install -Dm644 usr/share/man/man1/bazel-compile-commands.1 $out/share/man/man1/bazel-compile-commands.1
    install -Dm644 usr/share/man/man1/bazel-clangd-wrapper.1 $out/share/man/man1/bazel-clangd-wrapper.1
    install -Dm644 ${licenseSrc} $out/share/doc/bazel-compile-commands/LICENSE.txt
    runHook postInstall
  '';

  doInstallCheck = stdenvNoCC.buildPlatform.canExecute stdenvNoCC.hostPlatform;

  passthru = {
    aarch64DarwinSrc = sources.aarch64-darwin;
    x86_64LinuxSrc = sources.x86_64-linux;
    aarch64LinuxSrc = sources.aarch64-linux;
    inherit licenseSrc;
    updateScript = nix-update-script {
      extraArgs = [
        "--version-regex=^bazel-compile-commands-v(.*)$"
        "--custom-dep=aarch64DarwinSrc"
        "--custom-dep=x86_64LinuxSrc"
        "--custom-dep=aarch64LinuxSrc"
        "--custom-dep=licenseSrc"
      ];
    };
  };

  meta = {
    description = "Generate compile_commands.json from a Bazel workspace";
    homepage = "https://github.com/kiron1/bazel-compile-commands";
    changelog = "https://github.com/kiron1/bazel-compile-commands/releases/tag/bazel-compile-commands-v${version}";
    license = lib.licenses.mit;
    mainProgram = "bazel-compile-commands";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
  };
}
