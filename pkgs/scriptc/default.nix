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
  version = "0.4.9";
  npmTarball =
    name: hash:
    fetchurl {
      url = "https://registry.npmjs.org/@scriptc/${name}/-/${name}-${version}.tgz";
      inherit hash;
    };
  sources = {
    aarch64-darwin = npmTarball "cli-darwin-arm64" "sha256-gd7F659/G3I+q/AZDkPnhrRnmRusJj5z6/aUjgPYytI=";
    x86_64-linux = npmTarball "cli-linux-x64-gnu" "sha256-iJbYm5P+QXsLz7kDZ/ZG4DWtGULQ1l3nxODOm4kPnOA=";
    aarch64-linux = npmTarball "cli-linux-arm64-gnu" "sha256-f6lWE2K1XnrCedToI54ZoSbFCr1joNl5PGMH8c2TvmY=";
  };
  llvmSources = {
    aarch64-darwin = npmTarball "llvm-darwin-arm64" "sha256-FS6nu5A0D8gDbopWjmDhtvMvH38ulpPWWpp8ERSaB+o=";
    x86_64-linux = npmTarball "llvm-linux-x64-gnu" "sha256-3R7S18pbD+df0sWkNvZuqHcAK3PGkX6d38bz2RsLjIc=";
    aarch64-linux = npmTarball "llvm-linux-arm64-gnu" "sha256-Hem8zW4D+LfkDrRPELhLwBCNW7a1VrGAWIPQFq3aaeA=";
  };
  runtimeSources = {
    aarch64-darwin = npmTarball "runtime-darwin-arm64" "sha256-su6ZTeTv4QZ9/B9yRnbGJ3TMRx9m+D9LAV1j+NhSRzA=";
    x86_64-linux = npmTarball "runtime-linux-x64-gnu" "sha256-7pBbE6Qf2RniSwO6rieprUa3fKhDcUHsFwPtqwjq92E=";
    aarch64-linux = npmTarball "runtime-linux-arm64-gnu" "sha256-JEkfvIV2tN9u31v4tm609LBpL092Bw0qGAp9gigKmt0=";
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
    # LLVM and the precompiled runtime are distributed separately since 0.4.7.
    mkdir -p "$out/lib/scriptc/"{llvm,runtime}
    tar -xzf ${llvmSources.${stdenvNoCC.hostPlatform.system}} \
      -C "$out/lib/scriptc/llvm" --strip-components=1
    tar -xzf ${runtimeSources.${stdenvNoCC.hostPlatform.system}} \
      -C "$out/lib/scriptc/runtime" --strip-components=1
    # npm drops the mode bits that install-native.mjs normally restores.
    chmod +x "$out/lib/scriptc/"{bin/scriptc,lib/scriptc-comptime,lib/typescript/lib/tsc,lib/tsc-ts/lib/tsc-ts,llvm/bin/scriptc-llvm-codegen}

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
      --set SCRIPTC_LLVM_PACKAGE "$out/lib/scriptc/llvm" \
      --set SCRIPTC_RUNTIME_PACK "$out/lib/scriptc/runtime" \
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
    aarch64DarwinLlvmSrc = llvmSources.aarch64-darwin;
    x86_64LinuxLlvmSrc = llvmSources.x86_64-linux;
    aarch64LinuxLlvmSrc = llvmSources.aarch64-linux;
    aarch64DarwinRuntimeSrc = runtimeSources.aarch64-darwin;
    x86_64LinuxRuntimeSrc = runtimeSources.x86_64-linux;
    aarch64LinuxRuntimeSrc = runtimeSources.aarch64-linux;
    updateScript = nix-update-script {
      extraArgs = [
        "--url=https://github.com/vercel-labs/scriptc"
        "--version-regex=^v([0-9]+[.][0-9]+[.][0-9]+)$"
        "--custom-dep=aarch64DarwinSrc"
        "--custom-dep=x86_64LinuxSrc"
        "--custom-dep=aarch64LinuxSrc"
        "--custom-dep=aarch64DarwinLlvmSrc"
        "--custom-dep=x86_64LinuxLlvmSrc"
        "--custom-dep=aarch64LinuxLlvmSrc"
        "--custom-dep=aarch64DarwinRuntimeSrc"
        "--custom-dep=x86_64LinuxRuntimeSrc"
        "--custom-dep=aarch64LinuxRuntimeSrc"
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
