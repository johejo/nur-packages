{ pkgs }:
let
  sources = pkgs.callPackage ../_sources/generated.nix { };
in
{
  test = pkgs.callPackage ./test { };
  errorformat = pkgs.callPackage ./errorformat { source = sources.errorformat; };
  starlink-exporter = pkgs.callPackage ./starlink-exporter { source = sources.starlink-exporter; };
}
