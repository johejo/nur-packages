{ pkgsite }:

pkgsite.overrideAttrs (old: {
  # Also build the pkg.go.dev API client shipped alongside the doc server.
  subPackages = old.subPackages ++ [ "cmd/internal/pkgsite-cli" ];

  # Nothing is pinned locally, so nixpkgs owns updating this package.
  passthru = builtins.removeAttrs old.passthru [ "updateScript" ];
})
