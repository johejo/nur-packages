{
  wrangler,
  fetchFromGitHub,
  fetchPnpmDeps,
  pnpm_10,
  nix-update-script,
}:

wrangler.overrideAttrs (
  finalAttrs: old: {
    version = "4.144.0";

    src = fetchFromGitHub {
      owner = "cloudflare";
      repo = "workers-sdk";
      rev = "wrangler@${finalAttrs.version}";
      hash = "sha256-SdSEDS35x2WZaWzbV0gnlvX9XKoGpB/w6pckAdzXgk8=";
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
      hash = "sha256-irOzW8aYBd8jn5zp/S1K/KCHEl7gkk/Fw/+vF8dbz/U=";
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
