{ callPackageWithSourceMeta, ... }:
let
  zlib = callPackageWithSourceMeta ./zlib "apple-oss-distributions_zlib" { };
  berkeleydb = callPackageWithSourceMeta ./berkeleydb "apple-oss-distributions_berkeleydb" { };
  openldap = callPackageWithSourceMeta ./openldap "apple-oss-distributions_openldap" {
    inherit berkeleydb;
  };
in
{
  inherit zlib berkeleydb;
  # inherit openldap; # broken
  curl = callPackageWithSourceMeta ./curl "apple-oss-distributions_curl" {
    inherit zlib;
  };
  openssh = callPackageWithSourceMeta ./openssh "apple-oss-distributions_openssh" {
    inherit zlib;
  };
}
