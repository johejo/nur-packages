{ pkgs, system }:
let
  sources = pkgs.callPackage ../_sources/generated.nix { };
  sourceMeta = (builtins.fromJSON (builtins.readFile ../_sources/meta.json)).packages;
  getSourceFields =
    sourceName:
    let
      pkgMeta = sourceMeta.${sourceName} or { };
    in
    if builtins.isAttrs pkgMeta && pkgMeta ? fields && builtins.isAttrs pkgMeta.fields then
      pkgMeta.fields
    else
      { };
  getSourceMeta = sourceName: sourceMeta.${sourceName} or { };
  withSourceMeta =
    sourceName: drv:
    let
      fields = getSourceFields sourceName;
    in
    if fields == { } then
      drv
    else
      drv.overrideAttrs (old: {
        meta =
          (old.meta or { })
          // (if fields ? description then { description = fields.description; } else { })
          // (if fields ? homepage then { homepage = fields.homepage; } else { });
      });
  callPackageWithSourceMeta =
    path: sourceName: args:
    withSourceMeta sourceName (pkgs.callPackage path (args // { source = sources.${sourceName}; }));
  libz-rs-sys-cdylib = callPackageWithSourceMeta ./zlib-rs/libz-rs-sys-cdylib "zlib-rs" { };
in
{
  errorformat = callPackageWithSourceMeta ./errorformat "errorformat" { };
  gogcli = callPackageWithSourceMeta ./gogcli "gogcli" { sourceMeta = getSourceMeta "gogcli"; };
  starlink-exporter = callPackageWithSourceMeta ./starlink-exporter "starlink-exporter" { };
  kubernetes-mcp-server = callPackageWithSourceMeta ./kubernetes-mcp-server "kubernetes-mcp-server" {
    sourceMeta = getSourceMeta "kubernetes-mcp-server";
  };
  gitbucket = callPackageWithSourceMeta ./gitbucket "gitbucket" { };
  prometheus-jmx-exporter = callPackageWithSourceMeta ./prometheus-jmx-exporter "prometheus-jmx-exporter" { };
  codex-bin =
    let
      sourceName = "codex-${system}-bin";
    in
    if builtins.hasAttr sourceName sources then
      withSourceMeta sourceName (
        pkgs.callPackage ./codex-bin {
          source = sources.${sourceName};
          zlib = libz-rs-sys-cdylib;
        }
      )
    else
      null;
  caddy = pkgs.callPackage ./caddy { };
  kakehashi = callPackageWithSourceMeta ./kakehashi "kakehashi" { };
  hev-socks5-server = callPackageWithSourceMeta ./hev-socks5-server "hev-socks5-server" {
    sourceMeta = getSourceMeta "hev-socks5-server";
  };
  socks5shim = callPackageWithSourceMeta ./socks5shim "socks5shim" { };
  gf-cli = callPackageWithSourceMeta ./gf-cli "gf-cli" { };
  perl5-devel = callPackageWithSourceMeta ./perl5-devel "perl5" { };
  octorus = callPackageWithSourceMeta ./octorus "octorus" { };
  inherit libz-rs-sys-cdylib;

  apple-oss-distributions = import ./apple-oss-distributions {
    inherit callPackageWithSourceMeta;
  };
}
