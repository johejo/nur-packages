{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  clang,
  llvmPackages,
  nodejs_24,
  nix-update-script,
  versionCheckHook,
  stdenv,
  zlib,
}:

let
  version = "0.2.5";
  npmTarball =
    name: hash:
    fetchurl {
      url = "https://registry.npmjs.org/@scriptc/${name}/-/${name}-${version}.tgz";
      inherit hash;
    };
  sources = {
    aarch64-darwin = npmTarball "cli-darwin-arm64" "sha256-eEN2Ye+JrHGdHMCeCCee9kh4C2J4apDNUA/3JzMHrRQ=";
    x86_64-linux = npmTarball "cli-linux-x64-gnu" "sha256-W/5ue4wC2+WI7OpfjqQtoIK3o/dAux7sEWekEGQj/cI=";
    aarch64-linux = npmTarball "cli-linux-arm64-gnu" "sha256-VuLjfA1oMBvVjk+nMarsVKwXK5U4PbPgzMUBgJgRT+Q=";
  };
in
stdenvNoCC.mkDerivation {
  pname = "scriptc";
  inherit version;
  src = sources.${stdenvNoCC.hostPlatform.system};

  nativeBuildInputs = [
    makeWrapper
  ]
  ++ lib.optionals stdenvNoCC.hostPlatform.isLinux [ autoPatchelfHook ];

  # scriptc-llvm-codegen links against zlib and libstdc++.
  buildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [
    stdenv.cc.cc.lib
    zlib
  ];

  installPhase = ''
    runHook preInstall

    # The native compiler finds its toolchain through bin/scriptc.json,
    # whose paths are relative to the executable.
    mkdir -p "$out/lib/scriptc"
    cp -r dist/. "$out/lib/scriptc/"
    # npm drops the mode bits that install-native.mjs normally restores.
    chmod +x "$out/lib/scriptc/"{bin/scriptc,lib/scriptc-comptime,lib/typescript/lib/tsc,lib/llvm/bin/scriptc-llvm-codegen}

    ${
      if stdenvNoCC.hostPlatform.isLinux then
        ''
          makeWrapper ${lib.getExe clang} "$out/libexec/scriptc/clang" \
            --add-flags "-I${lib.getDev zlib}/include" \
            --add-flags "-L${lib.getLib zlib}/lib" \
            --add-flags "-Wl,-rpath,${lib.getLib zlib}/lib"
        ''
      else
        ''
          makeWrapper /usr/bin/clang "$out/libexec/scriptc/clang"
        ''
    }

    makeWrapper "$out/lib/scriptc/bin/scriptc" "$out/bin/scriptc" \
      --prefix PATH : "$out/libexec/scriptc:${
        lib.makeBinPath [
          llvmPackages.bintools
          nodejs_24
        ]
      }"

    runHook postInstall
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgramArg = "--version";

  passthru = {
    aarch64DarwinSrc = sources.aarch64-darwin;
    x86_64LinuxSrc = sources.x86_64-linux;
    aarch64LinuxSrc = sources.aarch64-linux;
    updateScript = nix-update-script {
      extraArgs = [
        "--url=https://github.com/vercel-labs/scriptc"
        "--custom-dep=aarch64DarwinSrc"
        "--custom-dep=x86_64LinuxSrc"
        "--custom-dep=aarch64LinuxSrc"
      ];
    };
  };

  meta = {
    description = "Compile TypeScript and JavaScript to native executables";
    longDescription = ''
      Compile TypeScript and JavaScript to native executables. On Linux, the
      default native compiler is nixpkgs' wrapped Clang, so its output depends
      on the Nix-provided runtime. For output intended for non-Nix Linux hosts,
      provide Zig and set SCRIPTC_CC=zigcc.
    '';
    homepage = "https://scriptc.dev";
    changelog = "https://github.com/vercel-labs/scriptc/releases/tag/v${version}";
    license = lib.licenses.asl20;
    mainProgram = "scriptc";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = builtins.attrNames sources;
  };
}
