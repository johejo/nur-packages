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
  meta = {
    description = "Starlink Prometheus Exporter Monitoring Stack";
    homepage = "https://github.com/clarkzjw/starlink_exporter";
    license = lib.licenses.gpl3Plus;
    changelog = "https://github.com/clarkzjw/starlink_exporter/releases/tag/${version}";
    mainProgram = "starlink_exporter";
  };
}
