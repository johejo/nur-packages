{ pkgs, system }:
let
  extractNodeEnv = pkgs.callPackage ../lib/extract-node-env.nix { };
in
{
  alerter-bin = pkgs.callPackage ./alerter-bin { };
  apfel-bin = pkgs.callPackage ./apfel-bin { };
  clawpatrol = pkgs.callPackage ./clawpatrol { };
  clawpatrol-bin = pkgs.callPackage ./clawpatrol-bin { };
  errorformat = pkgs.callPackage ./errorformat { };
  gcx-bin = pkgs.callPackage ./gcx-bin { };
  gogcli-bin = pkgs.callPackage ./gogcli-bin { };
  gotmpl = pkgs.callPackage ./gotmpl { };
  gotmplfmt = pkgs.callPackage ./gotmplfmt { };
  yamcel = pkgs.callPackage ./yamcel { };
  kubectl-schedsim = pkgs.callPackage ./kubectl-schedsim { };
  argocdapp2helmfile = pkgs.callPackage ./argocdapp2helmfile { };
  mdfix = pkgs.callPackage ./mdfix { };
  prometheus-jq-exporter = pkgs.callPackage ./prometheus-jq-exporter { };
  prometheus-jq-sd = pkgs.callPackage ./prometheus-jq-sd { };
  prometheus-nature-remo-exporter = pkgs.callPackage ./prometheus-nature-remo-exporter { };
  prometheus-tailscale-sd = pkgs.callPackage ./prometheus-tailscale-sd { };
  starlink-tools = pkgs.callPackage ./starlink-tools { };
  starlink-exporter = pkgs.callPackage ./starlink-exporter { };
  kubernetes-mcp-server-bin = pkgs.callPackage ./kubernetes-mcp-server-bin { };
  zot-bin = pkgs.callPackage ./zot-bin { };
  kwok-bin = pkgs.callPackage ./kwok-bin { };
  gitbucket = pkgs.callPackage ./gitbucket { };
  prometheus-jmx-exporter = pkgs.callPackage ./prometheus-jmx-exporter { };
  scriptc = pkgs.callPackage ./scriptc { };
  confluence-cli = pkgs.callPackage ./confluence-cli {
    inherit extractNodeEnv;
  };
  jira-cli = pkgs.callPackage ./jira-cli { inherit extractNodeEnv; };
  codex-bin = pkgs.callPackage ./codex-bin { };
  libduckdb-bin = pkgs.callPackage ./libduckdb-bin { };
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
  hev-socks5-server = pkgs.callPackage ./hev-socks5-server { };
  hocage = pkgs.callPackage ./hocage { };
  json2table = pkgs.callPackage ./json2table { };
  json2toml = pkgs.callPackage ./json2toml { };
  socks5shim = pkgs.callPackage ./socks5shim { };
  gf-cli = pkgs.callPackage ./gf-cli { };
  aws-sigv4-proxy = pkgs.callPackage ./aws-sigv4-proxy { };
  awsigv4-proxy = pkgs.callPackage ./awsigv4-proxy { };
  asciigraph = pkgs.callPackage ./asciigraph { };
  kakehashi-bin = pkgs.callPackage ./kakehashi-bin { };
  meat = pkgs.callPackage ./meat { };
  mise-bin = pkgs.callPackage ./mise-bin { };
  pitchfork-bin = pkgs.callPackage ./pitchfork-bin { };
  tuicr-bin = pkgs.callPackage ./tuicr-bin { };
  octorus-bin = pkgs.callPackage ./octorus-bin { };
  cclens-bin = pkgs.callPackage ./cclens-bin { };
  ghtkn-bin = pkgs.callPackage ./ghtkn-bin { };
  displayplacer = pkgs.callPackage ./displayplacer { };
  libz-rs-sys-cdylib = pkgs.callPackage ./zlib-rs/libz-rs-sys-cdylib { };
  xremap-gnome-bin =
    if
      builtins.elem system [
        "x86_64-linux"
        "aarch64-linux"
      ]
    then
      pkgs.callPackage ./xremap-gnome-bin { }
    else
      null;
  acli-bin = pkgs.callPackage ./acli-bin { };
  shelley-bin = pkgs.callPackage ./shelley-bin { };
}
