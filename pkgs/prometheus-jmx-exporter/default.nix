{
  lib,
  stdenvNoCC,
  formats,
  fetchurl,
  nix-update-script,
  ...
}:

let
  yaml = formats.yaml { };
  exporter_yaml = yaml.generate "exporter.yaml" { rules = [ { pattern = ".*"; } ]; };
in
stdenvNoCC.mkDerivation rec {
  pname = "prometheus-jmx-exporter";
  version = "1.6.0";
  src = fetchurl {
    url = "https://github.com/prometheus/jmx_exporter/releases/download/v${version}/jmx_prometheus_javaagent-${version}.jar";
    hash = "sha256-qVmD/ZboZdK835EcxQDnyCgIwnq5/SJr+WcytsPYxG4=";
  };
  dontUnpack = true;
  installPhase = ''
    mkdir -p $out/lib
    mkdir -p $out/etc
    cp "${src}" $out/lib/jmx_prometheus_javaagent.jar
    cp "${exporter_yaml}" $out/etc/exporter.yaml
  '';
  passthru.updateScript = nix-update-script { };
  meta = {
    description = "The JMX Exporter is a collector to capture JMX MBean values.";
    homepage = "https://github.com/prometheus/jmx_exporter";
    license = lib.licenses.asl20;
    changelog = "https://github.com/prometheus/jmx_exporter/releases/tag/v${version}";
  };
}
