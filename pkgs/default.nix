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
in
{
  alerter-bin = callPackageWithSource ./alerter-bin "alerter-bin" { };
  apfel-bin = callPackageWithSource ./apfel-bin "apfel-bin" { };
  clawpatrol = callPackageWithSource ./clawpatrol "clawpatrol" { };
  clawpatrol-bin = callPackageWithSystemSource ./clawpatrol-bin "clawpatrol" { };
  errorformat = callPackageWithSource ./errorformat "errorformat" { };
  gcx-bin = callPackageWithSystemSource ./gcx-bin "gcx" { };
  gogcli-bin = callPackageWithSystemSource ./gogcli-bin "gogcli" { };
  gotmpl = callPackageWithSource ./gotmpl "gotmpl" { };
  gotmplfmt = callPackageWithSource ./gotmplfmt "gotmplfmt" { };
  yamcel = callPackageWithSource ./yamcel "yamcel" { };
  kubectl-schedsim = callPackageWithSource ./kubectl-schedsim "kubectl-schedsim" { };
  argocdapp2helmfile = callPackageWithSource ./argocdapp2helmfile "argocdapp2helmfile" { };
  starlink-exporter = callPackageWithSource ./starlink-exporter "starlink-exporter" { };
  kubernetes-mcp-server-bin =
    callPackageWithSystemSource ./kubernetes-mcp-server-bin "kubernetes-mcp-server"
      { };
  zot-bin = callPackageWithSystemSource ./zot-bin "zot" { };
  kwok-bin =
    let
      kwokSourceName = "kwok-${system}-bin";
      kwokctlSourceName = "kwokctl-${system}-bin";
    in
    if builtins.hasAttr kwokSourceName sources && builtins.hasAttr kwokctlSourceName sources then
      pkgs.callPackage ./kwok-bin {
        kwokSource = sources.${kwokSourceName};
        kwokctlSource = sources.${kwokctlSourceName};
      }
    else
      null;
  gitbucket = callPackageWithSource ./gitbucket "gitbucket" { };
  prometheus-jmx-exporter =
    callPackageWithSource ./prometheus-jmx-exporter "prometheus-jmx-exporter"
      { };
  scriptc = callPackageWithSource ./scriptc "scriptc" { };
  confluence-cli = callPackageWithSource ./confluence-cli "confluence-cli" {
    inherit extractNodeEnv;
  };
  jira-cli = callPackageWithSource ./jira-cli "jira-cli" { inherit extractNodeEnv; };
  codex-bin = callPackageWithSystemSource ./codex-bin "codex" { };
  libduckdb-bin = callPackageWithSystemSource ./libduckdb-bin "libduckdb" { };
  caddy-with-plugins = pkgs.callPackage ./caddy { };
  helm-with-plugins =
    with pkgs;
    (wrapHelm kubernetes-helm {
      plugins = with kubernetes-helmPlugins; [
        helm-diff
        helm-unittest
        helm-s3
      ];
    });
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
  meat = callPackageWithSource ./meat "meat" { };
  mise-bin = callPackageWithSystemSource ./mise-bin "mise" { };
  pitchfork-bin = callPackageWithSystemSource ./pitchfork-bin "pitchfork" { };
  tuicr-bin = callPackageWithSystemSource ./tuicr-bin "tuicr" { };
  octorus-bin = callPackageWithSystemSource ./octorus-bin "octorus" { };
  cclens-bin = callPackageWithSystemSource ./cclens-bin "cclens" { };
  gws-bin = callPackageWithSystemSource ./gws-bin "gws" { };
  ghtkn-bin = callPackageWithSystemSource ./ghtkn-bin "ghtkn" { };
  displayplacer = callPackageWithSource ./displayplacer "displayplacer" { };
  libz-rs-sys-cdylib = callPackageWithSource ./zlib-rs/libz-rs-sys-cdylib "zlib-rs" { };
  xremap-gnome-bin = callPackageWithSystemSource ./xremap-gnome-bin "xremap" { };
  acli-bin = callPackageWithSystemSource ./acli-bin "acli" { };
}
