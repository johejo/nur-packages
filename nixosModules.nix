{ self }:
let
  starlinkExporterModule =
    args@{ pkgs, ... }:
    import ./modules/nixos/starlink-exporter.nix (
      args
      // {
        selfpkgs = self.packages.${pkgs.stdenv.hostPlatform.system};
      }
    );
in
{
  starlink-exporter = starlinkExporterModule;
}
