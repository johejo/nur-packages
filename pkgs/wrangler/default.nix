{
  wrangler,
  fetchFromGitHub,
  fetchPnpmDeps,
  pnpm_10,
  nix-update-script,
}:

wrangler.overrideAttrs (
  finalAttrs: old: {
    version = "4.148.0";

    src = fetchFromGitHub {
      owner = "cloudflare";
      repo = "workers-sdk";
      rev = "wrangler@${finalAttrs.version}";
      hash = "sha256-Wo8D86TSrG8yL8TrGmeZHzwhr6YoYHD2haDiRIUYEIY=";
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
      hash = "sha256-PkC5nBbUNqMVbpKPjBnpBtoZ4IV7aWJxV5MUgvFhoV4=";
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
