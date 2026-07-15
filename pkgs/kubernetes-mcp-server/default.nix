{
  lib,
  buildGoModule,
  versionCheckHook,
  source,
  ...
}:

buildGoModule rec {
  inherit (source) pname version src;
  vendorHash = "sha256-ddR/LQuldt+gHkUe3wqyrFMtUaN7dfBkDkThHxLmlYM=";
  subPackages = [ "cmd/kubernetes-mcp-server" ];
  ldflags =
    let
      mod = "github.com/containers/kubernetes-mcp-server/pkg/version";
    in
    [
      "-s"
      "-w"
      "-X ${mod}.CommitHash=${src.rev}"
      "-X ${mod}.Version=${version}"
    ];
  checkFlags = [ "-skip=Example_version" ];
  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];
  meta = {
    description = "A Model Context Protocol (MCP) server for Kubernetes and OpenShift";
    homepage = "https://github.com/containers/kubernetes-mcp-server";
    changelog = "https://github.com/containers/kubernetes-mcp-server/releases/tag/${version}";
    license = lib.licenses.asl20;
    mainProgram = "kubernetes-mcp-server";
  };
}
