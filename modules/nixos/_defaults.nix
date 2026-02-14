{
  pkgs,
  selfpkgs ? null,
}:
let
  sources = pkgs.callPackage ../../_sources/generated.nix { };
  localResolvers = {
    starlink-exporter =
      { pkgs, sources }:
      pkgs.callPackage ../../pkgs/starlink-exporter {
        source = sources.starlink-exporter;
      };
  };
in
builtins.mapAttrs (
  name: resolve:
  if selfpkgs != null && builtins.hasAttr name selfpkgs then
    builtins.getAttr name selfpkgs
  else
    resolve {
      inherit pkgs sources;
    }
) localResolvers
