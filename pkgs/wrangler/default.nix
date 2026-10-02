{
  wrangler,
  fetchFromGitHub,
  fetchPnpmDeps,
  pnpm_10,
  nix-update-script,
}:

wrangler.overrideAttrs (
  finalAttrs: old: {
    version = "4.145.0";

    src = fetchFromGitHub {
      owner = "cloudflare";
      repo = "workers-sdk";
      rev = "wrangler@${finalAttrs.version}";
      hash = "sha256-jtCjkT2Y+Y+uhnPd1i1QmO+Lavykb1l9LmuzC5FlmNs=";
    };

    pnpmDeps = fetchPnpmDeps {
      inherit (finalAttrs)
        pname
        version
        src
        postPatch
        ;
      pnpm = pnpm_10;
      fetcherVersion = 3;
      hash = "sha256-LbpV0QLzIgY/NVIgk85av5NAl7YcKBOPLHEGSaKzBsg=";
    };

    passthru = old.passthru // {
      updateScript = nix-update-script {
        extraArgs = [
          "--version-regex=wrangler@(.*)"
        ];
      };
    };
  }
)
