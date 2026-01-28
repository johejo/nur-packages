{ pkgs }:
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
}
