{
  pkgs,
  selfpkgs ? null,
}:
let
  localResolvers = {
    starlink-exporter =
      { pkgs }:
      pkgs.callPackage ../../pkgs/starlink-exporter { };
  };
in
builtins.mapAttrs (
  name: resolve:
  if selfpkgs != null && builtins.hasAttr name selfpkgs then
    builtins.getAttr name selfpkgs
  else
    resolve {
      inherit pkgs;
    }
) localResolvers
