{
  lib,
  buildGoModule,
  source,
  ...
}:

buildGoModule rec {
  inherit (source) pname version src;
  subPackages = [ "cmd/starlink_exporter" ];
  vendorHash = null;
  ldflags = [
    "-s"
    "-w"
  ];
  meta = {
    description = "Starlink Prometheus Exporter Monitoring Stack";
    homepage = "https://github.com/clarkzjw/starlink_exporter";
    changelog = "https://github.com/clarkzjw/starlink_exporter/releases/tag/${version}";
    license = lib.licenses.gpl3Only;
    mainProgram = "starlink_exporter";
  };
}
