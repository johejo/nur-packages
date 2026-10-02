{
  lib,
  stdenv,
  fetchFromGitHub,
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
  version = "1.0.0-beta.10";

  src = fetchFromGitHub {
    owner = "cloudflare";
    repo = "cf";
    tag = "cf@${finalAttrs.version}";
    hash = "sha256-rq6cBYVqPktI3Vh4mRosUV2LnvuyY3H3YY0vUimSzmg=";
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
    hash = "sha256-O0fzwFUIKkTyWHeOVAfyV/dDUoXbrrMNtXihb0thFOk=";
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

  buildPhase = ''
    runHook preBuild
    # The generated commands and SDK are committed, so skip `generate`
    # (which fetches the OpenAPI document from the network).
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
