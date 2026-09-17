{
  lib,
  buildGoModule,
  cacert,
  deno,
  fetchFromGitHub,
  nix-update-script,
  stdenvNoCC,
  versionCheckHook,
  ...
}:

let
  version = "0.5.10";
  src = fetchFromGitHub {
    owner = "denoland";
    repo = "clawpatrol";
    tag = "v${version}";
    hash = "sha256-/+8ZpsDuFGZc5D9Pov4wJG/S/QlNX+0HPXoTFmg7YdE=";
  };
  denoDepsFor =
    system:
    let
      denoOs = if system == "aarch64-darwin" then "darwin" else "linux";
      denoArch = if system == "x86_64-linux" then "x64" else "arm64";
    in
    stdenvNoCC.mkDerivation {
      pname = "clawpatrol-deno-deps-${system}";
      inherit version src;

      nativeBuildInputs = [
        cacert
        deno
      ];

      dontConfigure = true;

      buildPhase = ''
        runHook preBuild

        export DENO_DIR="$TMPDIR/deno"
        cd dashboard
        deno install --frozen --os ${denoOs} --arch ${denoArch}

        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall

        mkdir -p "$out"
        cp -R node_modules/. "$out/"

        runHook postInstall
      '';

      outputHashMode = "recursive";
      outputHashAlgo = "sha256";
      outputHash =
        {
          aarch64-darwin = "sha256-pF4tCpkV8tVWp19cg0ltrZ3a0p6cpmPQmN0Gua82m8I=";
          aarch64-linux = "sha256-A2tS2tN5gHN/6eoNEI5Khre5IlmtTDwZhi0S+ZjUHy8=";
          x86_64-linux = "sha256-J1yd2Trt1BqLNCM0k+RqT5JVds1s/zcifOPFmaQIi6c=";
        }
        .${system};

      dontFixup = true;
    };
  denoDepsBySystem = {
    aarch64-darwin = denoDepsFor "aarch64-darwin";
    aarch64-linux = denoDepsFor "aarch64-linux";
    x86_64-linux = denoDepsFor "x86_64-linux";
  };
  denoDeps = denoDepsBySystem.${stdenvNoCC.hostPlatform.system};
in
buildGoModule rec {
  pname = "clawpatrol";
  inherit version src;

  patches = [ ./env-pushdown-fetcher-darwin.patch ];

  vendorHash = "sha256-CkR30nTjzVtM9ZnwQmG5r7P7gMhiEXSBeeTBXEUPyaE=";

  nativeBuildInputs = [ deno ];

  postPatch = ''
    cp -R ${denoDeps}/. dashboard/node_modules/
    chmod -R +w dashboard/node_modules
  '';

  preBuild = ''
    export DENO_DIR="$TMPDIR/deno"
    (
      cd dashboard
      deno task --node-modules-dir=manual build
    )
  '';

  # Do not build the dashboard while vendoring Go modules.
  overrideModAttrs = _: {
    postPatch = "";
    preBuild = "";
  };

  ldflags = [
    "-s"
    "-w"
    "-X main.buildVersion=${version}"
  ];

  subPackages = [ "cmd/clawpatrol" ];

  # The test suite builds and executes external plugins, which requires a
  # writable home directory, networked Go module lookups, and sandbox-exec.
  doCheck = false;

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;

  preVersionCheck = ''
    version="''${version#v}"
  '';

  passthru = {
    aarch64DarwinDenoDeps = denoDepsBySystem.aarch64-darwin;
    aarch64LinuxDenoDeps = denoDepsBySystem.aarch64-linux;
    x86_64LinuxDenoDeps = denoDepsBySystem.x86_64-linux;
    updateScript = nix-update-script {
      extraArgs = [
        "--custom-dep=aarch64DarwinDenoDeps"
        "--custom-dep=aarch64LinuxDenoDeps"
        "--custom-dep=x86_64LinuxDenoDeps"
      ];
    };
  };

  meta = {
    description = "Security firewall for agents";
    homepage = "https://clawpatrol.dev";
    changelog = "https://github.com/denoland/clawpatrol/releases/tag/v${version}";
    license = lib.licenses.mit;
    mainProgram = "clawpatrol";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
  };
}
