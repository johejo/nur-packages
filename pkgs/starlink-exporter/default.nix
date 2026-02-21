{
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
    changelog = "https://github.com/clarkzjw/starlink_exporter/releases/tag/${version}";
    mainProgram = "starlink_exporter";
  };
}
