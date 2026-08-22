{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
  ...
}:

buildGoModule rec {
  pname = "starlink-exporter";
  version = "v20250818";

  src = fetchFromGitHub {
    owner = "clarkzjw";
    repo = "starlink_exporter";
    tag = version;
    hash = "sha256-hPbZC3R9i/ftMrZz727ACY09H3cX91OyJ47YgjM/nS4=";
  };

  subPackages = [ "cmd/starlink_exporter" ];
  vendorHash = null;
  ldflags = [
    "-s"
    "-w"
  ];

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Starlink Prometheus Exporter Monitoring Stack";
    homepage = "https://github.com/clarkzjw/starlink_exporter";
    changelog = "https://github.com/clarkzjw/starlink_exporter/releases/tag/${version}";
    license = lib.licenses.gpl3Only;
    mainProgram = "starlink_exporter";
  };
}
