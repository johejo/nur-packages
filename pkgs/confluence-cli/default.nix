{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  importNpmLock,
  jq,
  makeDenoNodeWrapper,
  nix-update-script,
  versionCheckHook,
  ...
}:

buildNpmPackage rec {
  pname = "confluence-cli";
  version = "2.30.0";
  src = fetchFromGitHub {
    owner = "pchuri";
    repo = "confluence-cli";
    tag = "v${version}";
    hash = "sha256-y+sDpKkz4nb7/2Nhhm18G3v5vMdEUZ9zaZRBSt3D8eg=";
  };

  postPatch = ''
    mv bin/index.js bin/index.cjs
    substituteInPlace package.json \
      --replace-fail "bin/index.js" "bin/index.cjs"
  '';

  npmDeps = importNpmLock { npmRoot = src; };

  npmConfigHook = importNpmLock.npmConfigHook;

  dontPatchShebangs = true;

  nativeBuildInputs = [ makeDenoNodeWrapper ];

  postInstall = ''
    packageRoot="$out/lib/node_modules/confluence-cli"
    sed -i '1s|^#!.*node$|#!/usr/bin/env node|' \
      "$packageRoot/node_modules/markdown-it/bin/markdown-it.mjs"

    makeDenoNodeWrapper \
      --package-root "$packageRoot" \
      --entry "$packageRoot/bin/index.cjs" \
      --bin confluence \
      --bin confluence-cli \
      --env-prefix CONFLUENCE_ \
      --allow-run ${lib.getExe jq} \
      -- --prefix PATH : ${lib.makeBinPath [ jq ]}
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
