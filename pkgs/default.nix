{ pkgs, system }:
let
  sources = pkgs.callPackage ../_sources/generated.nix { };
in
{
  errorformat = pkgs.callPackage ./errorformat { source = sources.errorformat; };
  gogcli = pkgs.callPackage ./gogcli { source = sources.gogcli; };
  starlink-exporter = pkgs.callPackage ./starlink-exporter { source = sources.starlink-exporter; };
  kubernetes-mcp-server = pkgs.callPackage ./kubernetes-mcp-server {
    source = sources.kubernetes-mcp-server;
  };
  gitbucket = pkgs.callPackage ./gitbucket { source = sources.gitbucket; };
  prometheus-jmx-exporter = pkgs.callPackage ./prometheus-jmx-exporter {
    source = sources.prometheus-jmx-exporter;
  };
  codex-bin =
    if sources ? "codex-${system}-bin" then
      pkgs.callPackage ./codex-bin { source = sources."codex-${system}-bin"; }
    else
      null;
  caddy = pkgs.callPackage ./caddy { };
  kakehashi = pkgs.callPackage ./kakehashi { source = sources.kakehashi; };
  gf-cli = pkgs.callPackage ./gf-cli { source = sources.gf-cli; };

  apple-oss-distributions = import ./apple-oss-distributions {
    inherit pkgs sources;
  };
}
