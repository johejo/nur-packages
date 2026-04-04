{
  buildGoModule,
  versionCheckHook,
  source,
  sourceMeta ? { },
  ...
}:

buildGoModule rec {
  inherit (source) pname version src;
  vendorHash = "sha256-JlbkmVa1CbfybU2554p0yuf1NsSqx3ZohZCcWpoFWgo=";
  subPackages = [ "cmd/kubernetes-mcp-server" ];
  ldflags =
    let
      mod = "github.com/containers/kubernetes-mcp-server/pkg/version";
      sourceGit = sourceMeta.git or { };
      commit = sourceGit.commit or sourceGit.ref or source.rev;
    in
    [
      "-s"
      "-w"
      "-X ${mod}.CommitHash=${commit}"
      "-X ${mod}.Version=${version}"
    ];
  checkFlags = [ "-skip=Example_version" ];
  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];
  meta = {
    changelog = "https://github.com/containers/kubernetes-mcp-server/releases/tag/${version}";
    mainProgram = "kubernetes-mcp-server";
  };
}
