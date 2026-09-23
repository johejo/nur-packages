{
  lib,
  buildNpmPackage,
  deno,
  extractNodeEnv,
  fetchFromGitHub,
  importNpmLock,
  jq,
  makeWrapper,
  nix-update-script,
  patchDebugEnv,
  versionCheckHook,
  ...
}:

let
  extraEnv = [
    "TMPDIR"
    "TMP"
    "TEMP"
    "HTTP_PROXY"
    "HTTPS_PROXY"
    "ALL_PROXY"
    "NO_PROXY"
    "http_proxy"
    "https_proxy"
    "all_proxy"
    "no_proxy"
  ];
in
buildNpmPackage rec {
  pname = "jira-cli";
  version = "2.12.0";
  src = fetchFromGitHub {
    owner = "pchuri";
    repo = "jira-cli";
    tag = "v${version}";
    hash = "sha256-ahoXZfCqcpYjzpbOwkUz9f4EiGztbKquoJMzm1gBBPA=";
  };

  postPatch = ''
    mv bin/index.js bin/index.cjs
    substituteInPlace package.json \
      --replace-fail "./bin/index.js" "./bin/index.cjs"
  '';

  npmDeps = importNpmLock { npmRoot = src; };

  npmConfigHook = importNpmLock.npmConfigHook;

  npmPackFlags = [ "--ignore-scripts" ];

  dontNpmBuild = true;

  nativeBuildInputs = [
    extractNodeEnv
    jq
    makeWrapper
    patchDebugEnv
  ];

  postInstall = ''
    packageRoot="$out/lib/node_modules/@pchuri/jira-cli"
    debugEnv="$(patch-debug-env --format json "$packageRoot/node_modules/debug/src/node.js")"

    allowEnv="$(
      extract-node-env \
        --format json \
        --include-literal-prefix JIRA_ \
        "$packageRoot/bin" \
        "$packageRoot/lib" \
        "$packageRoot/node_modules" |
        jq -r \
          --argjson extra '${builtins.toJSON extraEnv}' \
          --argjson debug "$debugEnv" \
          '. + $extra + $debug | unique | join(",")'
    )"

    echo "Allowing environment variables: $allowEnv"

    rm "$out/bin/jira"
    makeWrapper ${deno}/bin/deno "$out/bin/jira" \
      --set DENO_NO_UPDATE_CHECK 1 \
      --add-flags run \
      --add-flags --allow-read \
      --add-flags --allow-write \
      --add-flags --allow-net \
      --add-flags --allow-sys=homedir,uid \
      --add-flags "--allow-env=$allowEnv" \
      --add-flags "$out/lib/node_modules/@pchuri/jira-cli/bin/index.cjs"
  '';

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;
  postInstallCheck = ''
    "$out/bin/jira" --help > /dev/null
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Modern, extensible command-line interface for Atlassian JIRA";
    homepage = "https://github.com/pchuri/jira-cli";
    license = lib.licenses.isc;
    mainProgram = "jira";
  };
}
