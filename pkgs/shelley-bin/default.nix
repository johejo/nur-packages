{
  lib,
  stdenvNoCC,
  fetchurl,
  curl,
  jq,
  nix-update,
  versionCheckHook,
  writeShellApplication,
  ...
}:

let
  version = "0.1828.976657460";
  sources = {
    aarch64-darwin = fetchurl {
      url = "https://github.com/boldsoftware/shelley/releases/download/v${version}/shelley_darwin_arm64";
      hash = "sha256-wBRzjuwF/7QGFUfjHvLQhdP8xdQwHQuaPTO/b7DovE8=";
    };
    x86_64-linux = fetchurl {
      url = "https://github.com/boldsoftware/shelley/releases/download/v${version}/shelley_linux_amd64";
      hash = "sha256-3cTK6XpYi/B3zKfmvlUi0pqKGSQ9OYqwmWHQSwDNyiI=";
    };
    aarch64-linux = fetchurl {
      url = "https://github.com/boldsoftware/shelley/releases/download/v${version}/shelley_linux_arm64";
      hash = "sha256-fnTzUb1nl33jwjajLF2MOF/M0KI/lQvfr5PONdv9jQ8=";
    };
  };
in
stdenvNoCC.mkDerivation rec {
  pname = "shelley-bin";
  inherit version;
  src = sources.${stdenvNoCC.hostPlatform.system};

  dontUnpack = true;

  nativeInstallCheckInputs = [ versionCheckHook ];

  doInstallCheck = true;
  versionCheckProgramArg = "version";
  preVersionCheck = ''
    version="''${version#v}"
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/shelley
    runHook postInstall
  '';

  passthru = {
    aarch64DarwinSrc = sources.aarch64-darwin;
    x86_64LinuxSrc = sources.x86_64-linux;
    aarch64LinuxSrc = sources.aarch64-linux;
    updateScript = [
      (lib.getExe (writeShellApplication {
        name = "update-shelley-bin";
        runtimeInputs = [
          curl
          jq
          nix-update
        ];
        text = ''
          # The releases feed can advertise tags before binaries are published.
          headers=()
          if [[ -n "''${GITHUB_TOKEN:-}" ]]; then
            headers+=(-H "Authorization: Bearer $GITHUB_TOKEN")
          fi
          version="$(curl --fail --silent --show-error --location --retry 5 \
            "''${headers[@]}" https://api.github.com/repos/boldsoftware/shelley/releases |
            jq -er 'first(
              .[]
              | select(.draft == false and .prerelease == false)
              | select(([.assets[].name] | index("shelley_darwin_arm64")) != null
                   and ([.assets[].name] | index("shelley_linux_amd64")) != null
                   and ([.assets[].name] | index("shelley_linux_arm64")) != null)
              | .tag_name | capture("^v(?<version>[0-9]+[.][0-9]+[.][0-9]+)$").version
            )')"
          # Refresh hashes even when a previous attempt already set the version.
          for targetVersion in "$version" skip; do
            nix-update shelley-bin --flake \
              --version="$targetVersion" \
              --custom-dep=aarch64DarwinSrc \
              --custom-dep=x86_64LinuxSrc \
              --custom-dep=aarch64LinuxSrc
          done
        '';
      }))
    ];
  };

  meta = {
    description = "Mobile-friendly, web-based, multi-modal coding agent";
    homepage = "https://github.com/boldsoftware/shelley";
    changelog = "https://github.com/boldsoftware/shelley/releases/tag/v${version}";
    license = lib.licenses.asl20;
    mainProgram = "shelley";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
  };
}
