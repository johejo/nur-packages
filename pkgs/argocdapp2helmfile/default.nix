{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
  versionCheckHook,
  ...
}:

buildGoModule rec {
  pname = "argocdapp2helmfile";
  version = "0-unstable-2026-08-08";
  src = fetchFromGitHub {
    owner = "johejo";
    repo = "argocdapp2helmfile";
    rev = "0818d79eba2592b6e8215bf45b98fef01c77a1fc";
    hash = "sha256-VDjUtcHB4VwM8tW7Z7YPcOGJfVQAjbpkh5tjWA4lOqQ=";
  };
  vendorHash = "sha256-jK8kYEEPl+EZwhFYhWTGvdKxRDmo7g9QALwrb7beC6c=";

  ldflags = [ "-X main.version=${version}+rev.${builtins.substring 0 12 src.rev}" ];

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;
  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch=main" ]; };

  meta = {
    description = "Convert Argo CD Applications and ApplicationSets to helmfile";
    homepage = "https://github.com/johejo/argocdapp2helmfile";
    license = lib.licenses.mit;
    mainProgram = "argocdapp2helmfile";
    platforms = lib.platforms.unix;
  };
}
