{ pkgs, sources, ... }:
{
  curl = pkgs.callPackage ./curl { source = sources.curl-apple-oss-distributions; };
}
