{
  wrangler,
  fetchFromGitHub,
  fetchPnpmDeps,
  pnpm_10,
  nix-update-script,
}:

wrangler.overrideAttrs (
  finalAttrs: old: {
    version = "4.147.0";

    src = fetchFromGitHub {
      owner = "cloudflare";
      repo = "workers-sdk";
      rev = "wrangler@${finalAttrs.version}";
      hash = "sha256-AFWhs+9BmSy69hAxV3HKUFCTwLc3TZBg+f/1wM4caUw=";
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
      hash = "sha256-dPLKa9/+wNsaOrEPcfzI6MnqZPBab/SmaNbOk/sIcZw=";
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
