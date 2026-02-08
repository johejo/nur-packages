{ pkgs, sources, ... }:
let
  zlib = pkgs.callPackage ./zlib { source = sources.apple-oss-distributions_zlib; };
  berkeleydb = pkgs.callPackage ./berkeleydb { source = sources.apple-oss-distributions_berkeleydb; };
  openldap = pkgs.callPackage ./openldap {
    inherit berkeleydb;
    source = sources.apple-oss-distributions_openldap;
  };
in
{
  inherit zlib berkeleydb;
  # inherit openldap; # broken
  curl = pkgs.callPackage ./curl {
    inherit zlib;
    source = sources.apple-oss-distributions_curl;
  };
}
