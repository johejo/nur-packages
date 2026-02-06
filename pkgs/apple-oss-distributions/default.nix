{ pkgs, sources, ... }:
{
  zlib = pkgs.callPackage ./zlib { source = sources.apple-oss-distributions_zlib; };
  curl = pkgs.callPackage ./curl { source = sources.apple-oss-distributions_curl; };
}
