{ caddy, ... }:

caddy.withPlugins {
  plugins = [
    "github.com/caddy-dns/cloudflare@v0.2.4"
    "github.com/caddyserver/replace-response@v0.0.0-20250618171559-80962887e4c6"
    "github.com/mholt/caddy-dynamicdns@v0.0.0-20251231002810-1af4f8876598"
  ];
  hash = "sha256-p2vcm0TRj/G2SOjTC6TERi8bnEg9iziaunMzXRRkVUk=";
}
