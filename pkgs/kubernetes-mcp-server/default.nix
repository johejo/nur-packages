{
  lib,
  buildGoModule,
  source,
  ...
}:

buildGoModule rec {
  inherit (source) pname version src;
  vendorHash = "sha256-23CHIltcyYHqAsrtnhmwNx8Eg2eBRaj4pdacl7NZN7A=";
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
  meta = {
    description = "Model Context Protocol (MCP) server for Kubernetes and OpenShift";
    homepage = "https://github.com/containers/kubernetes-mcp-server";
    license = lib.licenses.asl20;
    changelog = "https://github.com/containers/kubernetes-mcp-server/releases/tag/${version}";
    mainProgram = "kubernetes-mcp-server";
  };
}
