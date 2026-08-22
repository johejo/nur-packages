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
    "DEBUG_HIDE_DATE"
    "DEBUG_COLORS"
    "DEBUG_DEPTH"
    "DEBUG_SHOW_HIDDEN"
    "http_proxy"
    "https_proxy"
    "all_proxy"
    "no_proxy"
  ];
in
buildNpmPackage rec {
  pname = "confluence-cli";
  version = "2.20.0";
  src = fetchFromGitHub {
    owner = "pchuri";
    repo = "confluence-cli";
    tag = "v${version}";
    hash = "sha256-xXy1wnBJ5B2oHSmlO4TOz0oveelIuB6hj1w71Btqb6U=";
  };

  postPatch = ''
    mv bin/index.js bin/index.cjs
    substituteInPlace package.json \
      --replace-fail "bin/index.js" "bin/index.cjs"
  '';

  npmDeps = importNpmLock { npmRoot = src; };

  npmConfigHook = importNpmLock.npmConfigHook;

  dontPatchShebangs = true;

  nativeBuildInputs = [
    extractNodeEnv
    jq
    makeWrapper
  ];

  postInstall = ''
    packageRoot="$out/lib/node_modules/confluence-cli"
    sed -i '1s|^#!.*node$|#!/usr/bin/env node|' \
      "$packageRoot/node_modules/markdown-it/bin/markdown-it.mjs"

    substituteInPlace "$packageRoot/node_modules/debug/src/node.js" \
      --replace-fail \
        'Object.keys(process.env).filter(key => {' \
        '["DEBUG_HIDE_DATE", "DEBUG_COLORS", "DEBUG_DEPTH", "DEBUG_SHOW_HIDDEN"].filter(key => process.env[key] !== undefined).filter(key => {'

    allowEnv="$(
      extract-node-env \
        --format json \
        --include-literal-prefix CONFLUENCE_ \
        "$packageRoot/bin" \
        "$packageRoot/lib" \
        "$packageRoot/node_modules" |
        jq -r \
          --argjson extra '${builtins.toJSON extraEnv}' \
          '. + $extra | unique | join(",")'
    )"

    echo "Allowing environment variables: $allowEnv"

    for bin in confluence confluence-cli; do
      rm "$out/bin/$bin"
      makeWrapper ${deno}/bin/deno "$out/bin/$bin" \
        --set DENO_NO_UPDATE_CHECK 1 \
        --prefix PATH : ${lib.makeBinPath [ jq ]} \
        --add-flags run \
        --add-flags --allow-read \
        --add-flags --allow-write \
        --add-flags --allow-net \
        --add-flags --allow-sys=homedir,uid \
        --add-flags "--allow-env=$allowEnv" \
        --add-flags --allow-run=${lib.getExe jq} \
        --add-flags "$out/lib/node_modules/confluence-cli/bin/index.cjs"
    done
  '';

  dontNpmBuild = true;

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;
  postInstallCheck = ''
    "$out/bin/confluence" --help > /dev/null
    "$out/bin/confluence-cli" --help > /dev/null
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "A command-line interface for Atlassian Confluence with page creation and editing capabilities";
    homepage = "https://github.com/pchuri/confluence-cli";
    license = lib.licenses.mit;
    mainProgram = "confluence";
  };
}
