{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchPnpmDeps,
  nodejs_24,
  pnpm_11,
  pnpmConfigHook,
  makeWrapper,
  clang,
  cmake,
  gnumake,
  llvmPackages,
  nix-update-script,
  zlib,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "scriptc";
  version = "0.0.35";
  src = fetchFromGitHub {
    owner = "vercel-labs";
    repo = "scriptc";
    tag = "v${finalAttrs.version}";
    hash = "sha256-PWg8LVZJxURxZXoly17fMJ29rRFij8lvL59H2cHtG7U=";
  };

  postPatch = ''
    substituteInPlace pnpm-workspace.yaml \
      --replace-fail "allowBuilds:" $'injectWorkspacePackages: true\nallowBuilds:'
    substituteInPlace pnpm-lock.yaml \
      --replace-fail "  excludeLinksFromLockfile: false" \
      $'  excludeLinksFromLockfile: false\n  injectWorkspacePackages: true'
  '';

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    pnpm = pnpm_11;
    fetcherVersion = 4;
    hash = "sha256-9JmtvgSW8+RDtbPGPDETjra1xUDkZG8K9GaEHUnNaL0=";
  };

  nativeBuildInputs = [
    nodejs_24
    pnpmConfigHook
    pnpm_11
    makeWrapper
  ];

  buildPhase = ''
    runHook preBuild

    pnpm --filter @scriptc/runtime --filter @scriptc/compiler --filter scriptc run build

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    pnpm --filter scriptc deploy --prod "$out/lib/scriptc"

    ${
      if stdenv.hostPlatform.isLinux then
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

    makeWrapper ${lib.getExe nodejs_24} "$out/bin/scriptc" \
      --add-flags "$out/lib/scriptc/dist/main.js" \
      --prefix PATH : "$out/libexec/scriptc:${
        lib.makeBinPath [
          cmake
          gnumake
          llvmPackages.bintools
        ]
      }"

    runHook postInstall
  '';

  doInstallCheck = true;

  installCheckPhase = ''
    runHook preInstallCheck

    test "$("$out/bin/scriptc" --version)" = "${finalAttrs.version}"
    "$out/bin/scriptc" --help >/dev/null

    runHook postInstallCheck
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Compile TypeScript and JavaScript to native executables";
    longDescription = ''
      Compile TypeScript and JavaScript to native executables. On Linux, the
      default native compiler is nixpkgs' wrapped Clang, so its output depends
      on the Nix-provided runtime. For output intended for non-Nix Linux hosts,
      provide Zig and set SCRIPTC_CC=zigcc.
    '';
    homepage = "https://scriptc.dev";
    changelog = "https://github.com/vercel-labs/scriptc/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.asl20;
    mainProgram = "scriptc";
    platforms = [
      "aarch64-darwin"
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
})
