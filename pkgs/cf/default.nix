{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchurl,
  fetchPnpmDeps,
  pnpmConfigHook,
  pnpm_12,
  nodejs,
  makeWrapper,
  cacert,
  jq,
  moreutils,
  nix-update-script,
  versionCheckHook,
  writableTmpDirAsHomeHook,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "cf";
  version = "1.0.0-beta.12";

  src = fetchFromGitHub {
    owner = "cloudflare";
    repo = "cf";
    tag = "cf@${finalAttrs.version}";
    hash = "sha256-Eproy+7wS0nROn7LOesjMofU+hmmxzq7NY+I2UKdTWw=";
  };

  # pnpm packageManager version in the root package.json may not match nixpkgs
  postPatch = ''
    jq 'del(.packageManager)' package.json | sponge package.json
  '';

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs)
      pname
      version
      src
      postPatch
      ;
    pnpm = pnpm_12;
    # pnpm 12 materializes packages under the store's `links` directory,
    # which contains non-JSON `*.json` files the fetcher's fixup cannot sort.
    # It is regenerated from the content-addressed files on install.
    preFixup = ''
      rm -rf $storePath/v11/links
    '';
    fetcherVersion = 4;
    hash = "sha256-9OQBTbaQggWnoPNnXiNENklCqxsijXVFzYhMcCmfhp0=";
  };

  nativeBuildInputs = [
    makeWrapper
    nodejs
    pnpmConfigHook
    pnpm_12
    jq
    moreutils
  ];

  env.NODE_OPTIONS = "--max-old-space-size=4096";

  # `build` depends on `generate`, which downloads the Forge OpenAPI document.
  # Must match FORGE_OPENAPI_VERSION in packages/cli/generate.ts.
  forgeOpenApi = fetchurl {
    url = "https://github.com/cloudflare/forge/releases/download/openapi@10cdded1d9e93c9b055e27cac83b397b2bd7f0c6/openapi.forge.json";
    hash = "sha256-czV4/2rqI1hIXLm8ah+jm64SIvgX4Xlc+mYceun18vM=";
  };

  # Read the prefetched document instead of fetching it. Not using
  # FORGE_OPENAPI_BUNDLE, since that also forces regenerating the committed SDK.
  preBuild = ''
    substituteInPlace packages/cli/generate.ts \
      --replace-fail "await fetchForgeOpenApi()" \
        "JSON.parse(readFileSync(\"$forgeOpenApi\", \"utf8\"))"
  '';

  buildPhase = ''
    runHook preBuild
    NODE_ENV=production pnpm --filter cf run build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/{bin,lib}
    pnpm config set --location=project injectWorkspacePackages true
    pnpm --filter=cf --prod deploy $out/lib/cf
    for bin in cf cloudflare; do
      makeWrapper ${lib.getExe nodejs} $out/bin/$bin \
        --inherit-argv0 \
        --add-flags $out/lib/cf/bin/cf \
        --set-default SSL_CERT_FILE "${cacert}/etc/ssl/certs/ca-bundle.crt"
    done
    runHook postInstall
  '';

  preFixup = ''
    stripExclude+=("*.js" "*.mjs" "*.ts" "*.map" "*.json" "*.md")
  '';

  nativeInstallCheckInputs = [
    versionCheckHook
    writableTmpDirAsHomeHook
  ];
  versionCheckKeepEnvironment = [ "HOME" ];
  doInstallCheck = true;

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--version=unstable"
      "--version-regex=cf@(.*)"
    ];
  };

  meta = {
    description = "The Cloudflare CLI";
    homepage = "https://github.com/cloudflare/cf";
    license = with lib.licenses; [
      mit
      asl20
    ];
    mainProgram = "cf";
    inherit (nodejs.meta) platforms;
  };
})
