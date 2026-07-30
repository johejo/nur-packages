{
  lib,
  buildGoModule,
  cacert,
  deno,
  stdenvNoCC,
  versionCheckHook,
  source,
  ...
}:

let
  denoOs = if stdenvNoCC.hostPlatform.isDarwin then "darwin" else "linux";
  denoArch = if stdenvNoCC.hostPlatform.isAarch64 then "arm64" else "x64";
  denoDeps = stdenvNoCC.mkDerivation {
    pname = "clawpatrol-deno-deps";
    inherit (source) version src;

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
        aarch64-darwin = "sha256-8s2S6g88B2awkp61ljvLu+xVt68OGZC0nldI8qttbbU=";
        aarch64-linux = "sha256-lP+9V7ou08cDovWNDiv63MiuO17Oon5TE3CnqK3We9U=";
        x86_64-linux = "sha256-q2ZkQpxcyxyzLuA8sE5bLRYvdezEBHdwsWdACAHyFxg=";
      }
      .${stdenvNoCC.hostPlatform.system};

    dontFixup = true;
  };
in
buildGoModule {
  pname = "clawpatrol";
  inherit (source) version src;

  patches = [ ./env-pushdown-fetcher-darwin.patch ];

  vendorHash = "sha256-9HIqm4PmmiDMFjBMqIlMtKlUBlKyKGkMWlDLSOoyVXE=";

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
    "-X main.buildVersion=${lib.removePrefix "v" source.version}"
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

  meta = {
    description = "Security firewall for agents";
    homepage = "https://clawpatrol.dev";
    changelog = "https://github.com/denoland/clawpatrol/releases/tag/${source.version}";
    license = lib.licenses.mit;
    mainProgram = "clawpatrol";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
  };
}
