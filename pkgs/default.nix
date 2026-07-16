{ pkgs, system }:
let
  sources = pkgs.callPackage ../_sources/generated.nix { };
  callPackageWithSource =
    path: sourceName: args:
    pkgs.callPackage path (args // { source = sources.${sourceName}; });
  callPackageWithSystemSource =
    path: sourcePrefix: args:
    let
      sourceName = "${sourcePrefix}-${system}-bin";
    in
    if builtins.hasAttr sourceName sources then
      pkgs.callPackage path (args // { source = sources.${sourceName}; })
    else
      null;
  extractNodeEnv = pkgs.callPackage ../lib/extract-node-env.nix { };
  libz-rs-sys-cdylib = callPackageWithSource ./zlib-rs/libz-rs-sys-cdylib "zlib-rs" { };
in
{
  alerter-bin = callPackageWithSource ./alerter-bin "alerter-bin" { };
  apfel-bin = callPackageWithSource ./apfel-bin "apfel-bin" { };
  errorformat = callPackageWithSource ./errorformat "errorformat" { };
  gcx-bin = callPackageWithSystemSource ./gcx-bin "gcx" { };
  gogcli-bin = callPackageWithSystemSource ./gogcli-bin "gogcli" { };
  gotmpl = callPackageWithSource ./gotmpl "gotmpl" { };
  gotmplfmt = callPackageWithSource ./gotmplfmt "gotmplfmt" { };
  starlink-exporter = callPackageWithSource ./starlink-exporter "starlink-exporter" { };
  kubernetes-mcp-server-bin =
    callPackageWithSystemSource ./kubernetes-mcp-server-bin "kubernetes-mcp-server"
      { };
  gitbucket = callPackageWithSource ./gitbucket "gitbucket" { };
  prometheus-jmx-exporter =
    callPackageWithSource ./prometheus-jmx-exporter "prometheus-jmx-exporter"
      { };
  confluence-cli = callPackageWithSource ./confluence-cli "confluence-cli" { };
  jira-cli = callPackageWithSource ./jira-cli "jira-cli" { inherit extractNodeEnv; };
  codex-bin = callPackageWithSystemSource ./codex-bin "codex" { zlib = libz-rs-sys-cdylib; };
  libduckdb-bin = callPackageWithSystemSource ./libduckdb-bin "libduckdb" { };
  caddy-with-plugins = pkgs.callPackage ./caddy { };
  helm-with-plugins =
    with pkgs;
    (wrapHelm kubernetes-helm { plugins = with kubernetes-helmPlugins; [ helm-diff ]; });
  hev-socks5-server = callPackageWithSource ./hev-socks5-server "hev-socks5-server" { };
  hocage = callPackageWithSource ./hocage "hocage" { };
  json2table = callPackageWithSource ./json2table "json2table" { };
  json2toml = callPackageWithSource ./json2toml "json2toml" { };
  socks5shim = callPackageWithSource ./socks5shim "socks5shim" { };
  gf-cli = callPackageWithSource ./gf-cli "gf-cli" { };
  aws-sigv4-proxy = callPackageWithSource ./aws-sigv4-proxy "aws-sigv4-proxy" { };
  awsigv4-proxy = callPackageWithSource ./awsigv4-proxy "awsigv4-proxy" { };
  asciigraph = callPackageWithSource ./asciigraph "asciigraph" { };
  kakehashi-bin = callPackageWithSystemSource ./kakehashi-bin "kakehashi" { };
  mise-bin = callPackageWithSystemSource ./mise-bin "mise" { };
  octorus-bin = callPackageWithSystemSource ./octorus-bin "octorus" { };
  gws-bin = callPackageWithSystemSource ./gws-bin "gws" { };
  displayplacer = callPackageWithSource ./displayplacer "displayplacer" { };
  inherit libz-rs-sys-cdylib;
  xremap-gnome-bin = callPackageWithSystemSource ./xremap-gnome-bin "xremap" { };
  acli-bin = callPackageWithSystemSource ./acli-bin "acli" { };
}
