{
  lib,
  buildGoModule,
  versionCheckHook,
  source,
  ...
}:

buildGoModule {
  inherit (source) pname version src;
  vendorHash = "sha256-jK8kYEEPl+EZwhFYhWTGvdKxRDmo7g9QALwrb7beC6c=";

  ldflags = [ "-X main.version=${source.version}" ];

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;

  meta = {
    description = "Convert Argo CD Applications and ApplicationSets to helmfile";
    homepage = "https://github.com/johejo/argocdapp2helmfile";
    license = lib.licenses.mit;
    mainProgram = "argocdapp2helmfile";
    platforms = lib.platforms.unix;
  };
}
