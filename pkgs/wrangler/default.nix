{
  wrangler,
  fetchFromGitHub,
  fetchPnpmDeps,
  pnpm_10,
  nix-update-script,
}:

wrangler.overrideAttrs (
  finalAttrs: old: {
    version = "4.143.0";

    src = fetchFromGitHub {
      owner = "cloudflare";
      repo = "workers-sdk";
      rev = "wrangler@${finalAttrs.version}";
      hash = "sha256-SrVkafOGFdDvkWbhJgRhzzW6+N76kVWokf3SpwnLosE=";
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
      hash = "sha256-iq21hQb/fZNwi2X5f1Qs3VF34jh9tg4gg5AX4OazOF8=";
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
