{
  config,
  lib,
  pkgs,
  selfpkgs ? null,
  ...
}:
let
  cfg = config.services.starlink-exporter;
  commonService = import ./systemd-service-common.nix;
  defaults = import ./_defaults.nix {
    inherit
      pkgs
      selfpkgs
      ;
  };
in
{
  options = {
    services.starlink-exporter = {
      enable = lib.mkEnableOption "Starlink Exporter for Prometheus";
      address = lib.mkOption {
        type = lib.types.str;
        default = "192.168.100.1:9200";
        description = "IP address and port to reach dish";
      };
      port = lib.mkOption {
        type = lib.types.port;
        default = 9817;
        description = "Listening port to expose metrics on";
      };
      package = lib.mkOption {
        type = lib.types.package;
        default = defaults.starlink-exporter;
        description = "Package to use for starlink-exporter service";
      };
    };
  };
  config = lib.mkIf cfg.enable {
    systemd.services.starlink-exporter = lib.recursiveUpdate commonService {
      description = "Starlink Exporter for Prometheus";
      after = [
        "network.target"
        "network-online.target"
      ];
      wants = [
        "network.target"
        "network-online.target"
      ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${lib.getExe cfg.package} -address=${cfg.address} -port=${toString cfg.port}";
        Restart = "on-failure";
        DynamicUser = true;
      };
    };
  };
}
