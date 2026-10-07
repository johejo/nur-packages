{ caddy, nix-update-script, ... }:

(caddy.withPlugins {
  plugins = [
    "github.com/caddy-dns/cloudflare@v0.2.4"
    "github.com/caddyserver/replace-response@v0.0.0-20250618171559-80962887e4c6"
    "github.com/mholt/caddy-dynamicdns@v0.0.0-20251231002810-1af4f8876598"
  ];
  hash = "sha256-o4lDrDZueY7J0E+upFzQzkLxY3s+gPv1ro+PKZ0Ebvw=";
}).overrideAttrs
  (old: {
    # Keep source positions local so nix-update can update the plugin source hash.
    version = caddy.version;
    src = old.src;

    passthru = old.passthru // {
      updateScript = nix-update-script {
        extraArgs = [ "--version=skip" ];
      };
    };
  })
