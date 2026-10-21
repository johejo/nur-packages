{ pkgs, system }:
let
  inherit (pkgs.lib) optionalAttrs;
  callPackage = pkgs.newScope {
    buildGoModule = pkgs.buildGo127Module;
  };
  extractNodeEnv = callPackage ../lib/extract-node-env.nix { };
  patchDebugEnv = callPackage ../lib/patch-debug-env.nix { };
  makeDenoNodeWrapper = callPackage ../lib/make-deno-node-wrapper.nix {
    inherit extractNodeEnv patchDebugEnv;
  };
in
{
  alerter-bin = callPackage ./alerter-bin { };
  apfel-llm = callPackage ./apfel-llm { };
  bazel-compile-commands-bin = callPackage ./bazel-compile-commands-bin { };
  clawpatrol = callPackage ./clawpatrol {
    buildGoModule = pkgs.buildGo126Module;
  };
  clawpatrol-bin = callPackage ./clawpatrol-bin { };
  errorformat = callPackage ./errorformat { };
  gcx-bin = callPackage ./gcx-bin { };
  gogcli-bin = callPackage ./gogcli-bin { };
  gotmpl = callPackage ./gotmpl { };
  gotmplfmt = callPackage ./gotmplfmt { };
  yamcel = callPackage ./yamcel { };
  kubectl-schedsim = callPackage ./kubectl-schedsim { };
  argocdapp2helmfile = callPackage ./argocdapp2helmfile { };
  mdfix = callPackage ./mdfix { };
  prometheus-exporter-merger = callPackage ./prometheus-exporter-merger { };
  prometheus-jq-exporter = callPackage ./prometheus-jq-exporter { };
  prometheus-jq-sd = callPackage ./prometheus-jq-sd { };
  prometheus-nature-remo-exporter = callPackage ./prometheus-nature-remo-exporter { };
  prometheus-tailscale-sd = callPackage ./prometheus-tailscale-sd { };
  starlink-tools = callPackage ./starlink-tools { };
  starlink-exporter = callPackage ./starlink-exporter { };
  kubernetes-mcp-server-bin = callPackage ./kubernetes-mcp-server-bin { };
  zot-bin = callPackage ./zot-bin { };
  kwok-bin = callPackage ./kwok-bin { };
  gitbucket = callPackage ./gitbucket { };
  prometheus-jmx-exporter = callPackage ./prometheus-jmx-exporter { };
  scriptc = callPackage ./scriptc { };
  confluence-cli = callPackage ./confluence-cli { inherit makeDenoNodeWrapper; };
  jira-cli = callPackage ./jira-cli { inherit makeDenoNodeWrapper; };
  container-bin = callPackage ./container-bin { };
  codex-bin = callPackage ./codex-bin { };
  libduckdb-bin = callPackage ./libduckdb-bin { };
  duckdb-bin = callPackage ./duckdb-bin { };
  wgpu-native-bin = callPackage ./wgpu-native-bin { };
  caddy-with-plugins = callPackage ./caddy { };
  helm-with-plugins =
    with pkgs;
    (wrapHelm kubernetes-helm {
      plugins = with kubernetes-helmPlugins; [
        helm-diff
        helm-unittest
        helm-s3
      ];
    });
  hev-socks5-server = callPackage ./hev-socks5-server { };
  hocage = callPackage ./hocage { };
  json2table = callPackage ./json2table { };
  json2toml = callPackage ./json2toml { };
  socks5shim = callPackage ./socks5shim { };
  gf-cli = callPackage ./gf-cli { };
  gfterm = callPackage ./gfterm { };
  tailctl = callPackage ./tailctl { };
  aws-sigv4-proxy = callPackage ./aws-sigv4-proxy { };
  awsigv4-proxy = callPackage ./awsigv4-proxy { };
  asciigraph = callPackage ./asciigraph { };
  kakehashi-bin = callPackage ./kakehashi-bin { };
  meat = callPackage ./meat { };
  mise-bin = callPackage ./mise-bin { };
  pitchfork-bin = callPackage ./pitchfork-bin { };
  tuicr-bin = callPackage ./tuicr-bin { };
  vector-bin = callPackage ./vector-bin { };
  xh-bin = callPackage ./xh-bin { };
  octorus-bin = callPackage ./octorus-bin { };
  cclens-bin = callPackage ./cclens-bin { };
  ghtkn-bin = callPackage ./ghtkn-bin { };
  displayplacer = callPackage ./displayplacer { };
  libz-rs-sys-cdylib = callPackage ./zlib-rs/libz-rs-sys-cdylib { };
  acli-bin = callPackage ./acli-bin { };
  shelley-bin = callPackage ./shelley-bin { };
  socktainer-bin = callPackage ./socktainer-bin { };
  pkgsite = callPackage ./pkgsite { };
  cf = callPackage ./cf { };
  wizcli-bin = callPackage ./wizcli-bin { };
}
//
  optionalAttrs
    (builtins.elem system [
      "x86_64-linux"
      "aarch64-linux"
    ])
    {
      tailcat-bin = callPackage ./tailcat-bin { };
      xremap-gnome-bin = callPackage ./xremap-gnome-bin { };
    }
// optionalAttrs (system == "aarch64-darwin") {
  devcontainer-apple = callPackage ./devcontainer-apple { };
}
