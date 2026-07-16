{
  lib,
  buildNpmPackage,
  importNpmLock,
  versionCheckHook,
  source,
  ...
}:

buildNpmPackage {
  inherit (source) pname src;
  version = lib.removePrefix "v" source.version;

  npmDeps = importNpmLock { npmRoot = source.src; };

  npmConfigHook = importNpmLock.npmConfigHook;

  npmPackFlags = [ "--ignore-scripts" ];

  dontNpmBuild = true;

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;

  meta = {
    description = "Modern, extensible command-line interface for Atlassian JIRA";
    homepage = "https://github.com/pchuri/jira-cli";
    license = lib.licenses.isc;
    mainProgram = "jira";
  };
}
