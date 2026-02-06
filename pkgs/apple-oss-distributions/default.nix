{ pkgs, sources, ... }:
{
  curl = pkgs.callPackage ./curl { source = sources.apple-oss-distributions_curl; };
}
