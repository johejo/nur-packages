{
  lib,
  buildGoModule,
  source,
  ...
}:

buildGoModule rec {
  inherit (source) pname version src;
  vendorHash = "sha256-nig3GI7eM1XRtIoAh1qH+9PxPPGynl01dCZ2ppyhmzU=";
  doCheck = false; # Tests require network access
  ldflags =
    let
      mod = "github.com/steipete/gogcli/internal/cmd";
    in
    [
      "-s"
      "-w"
      "-X ${mod}.version=${version}"
      "-X ${mod}.commit=${src.rev}"
    ];
  meta = {
    description = "Fast, script-friendly CLI for Google Workspace (Gmail, Calendar, Drive, Docs, etc.)";
    homepage = "https://github.com/steipete/gogcli";
    license = lib.licenses.mit;
    mainProgram = "gog";
  };
}
