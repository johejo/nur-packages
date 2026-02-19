{ pkgs, system }:
let
  sources = pkgs.callPackage ../_sources/generated.nix { };
  libz-rs-sys-cdylib = pkgs.callPackage ./zlib-rs/libz-rs-sys-cdylib { source = sources.zlib-rs; };
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
      pkgs.callPackage ./codex-bin {
        source = sources."codex-${system}-bin";
        zlib = libz-rs-sys-cdylib;
      }
    else
      null;
  caddy = pkgs.callPackage ./caddy { };
  kakehashi = pkgs.callPackage ./kakehashi { source = sources.kakehashi; };
  hev-socks5-server = pkgs.callPackage ./hev-socks5-server { source = sources.hev-socks5-server; };
  gf-cli = pkgs.callPackage ./gf-cli { source = sources.gf-cli; };
  perl5-devel = pkgs.callPackage ./perl5-devel { source = sources.perl5; };
  inherit libz-rs-sys-cdylib;

  apple-oss-distributions = import ./apple-oss-distributions {
    inherit pkgs sources;
  };
}
