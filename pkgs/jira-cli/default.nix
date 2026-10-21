{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  importNpmLock,
  makeDenoNodeWrapper,
  nix-update-script,
  versionCheckHook,
  ...
}:

buildNpmPackage rec {
  pname = "jira-cli";
  version = "3.0.4";
  src = fetchFromGitHub {
    owner = "pchuri";
    repo = "jira-cli";
    tag = "v${version}";
    hash = "sha256-qXzvbMnXMaDuMmKJNT2pcI/8XhPSq7Cd0NTxZGr89Bg=";
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

  nativeBuildInputs = [ makeDenoNodeWrapper ];

  postInstall = ''
    makeDenoNodeWrapper \
      --package-root "$out/lib/node_modules/@pchuri/jira-cli" \
      --entry "$out/lib/node_modules/@pchuri/jira-cli/bin/index.cjs" \
      --bin jira \
      --env-prefix JIRA_
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
