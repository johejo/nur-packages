{
  lib,
  stdenvNoCC,
  formats,
  source,
  ...
}:

let
  yaml = formats.yaml { };
  exporter_yaml = yaml.generate "exporter.yaml" { rules = [ { pattern = ".*"; } ]; };
in
stdenvNoCC.mkDerivation rec {
  inherit (source) pname version src;
  dontUnpack = true;
  installPhase = ''
    mkdir -p $out/lib
    mkdir -p $out/etc
    cp "${src}" $out/lib/jmx_prometheus_javaagent.jar
    cp "${exporter_yaml}" $out/etc/exporter.yaml
  '';
  meta = {
    description = "The JMX Exporter is a collector to capture JMX MBean values.";
    homepage = "https://github.com/prometheus/jmx_exporter";
    license = lib.licenses.asl20;
    changelog = "https://github.com/prometheus/jmx_exporter/releases/tag/${version}";
  };
}
