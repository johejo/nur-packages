{ pkgs, system }:
let
  sources = pkgs.callPackage ../_sources/generated.nix { };
  sourceMeta = (builtins.fromJSON (builtins.readFile ../_sources/meta.json)).packages;
  sourceMetaFor = sourceName: sourceMeta.${sourceName} or { };
  sourceFieldsFor =
    sourceName:
    let
      fields = (sourceMetaFor sourceName).fields or { };
    in
    if builtins.isAttrs fields then
      fields
    else
      { };
  tokenizeSpdxExpression =
    value:
    let
      normalized = builtins.replaceStrings
        [
          "("
          ")"
          " OR "
          " AND "
          " WITH "
          " / "
          "/"
        ]
        [
          ""
          ""
          "|"
          "|"
          "|"
          "|"
          "|"
        ]
        value;
    in
    pkgs.lib.filter (token: token != "") (map pkgs.lib.strings.trim (pkgs.lib.splitString "|" normalized));
  licensesBySpdxId = builtins.foldl' (
    acc: license:
    if
      builtins.isAttrs license
      && license ? spdxId
      && builtins.isString license.spdxId
      && license.spdxId != ""
    then
      if acc ? "${license.spdxId}" then
        acc
      else
        acc // { "${license.spdxId}" = license; }
    else
      acc
  ) { } (builtins.attrValues pkgs.lib.licenses);
  licenseFromSpdxExpression =
    value:
    let
      tokens = tokenizeSpdxExpression value;
      mappedKnown = pkgs.lib.filter (license: license != null) (
        map (spdx: licensesBySpdxId.${spdx} or null) tokens
      );
      uniqueLicenses = pkgs.lib.unique mappedKnown;
    in
    if uniqueLicenses == [ ] then
      null
    else if builtins.length uniqueLicenses == 1 then
      builtins.head uniqueLicenses
    else
      uniqueLicenses;
  metaOverridesFromFields =
    fields:
    let
      mappedLicense =
        if fields ? licenseSpdx && builtins.isString fields.licenseSpdx then
          licenseFromSpdxExpression fields.licenseSpdx
        else
          null;
      description =
        if fields ? description && builtins.isString fields.description then
          fields.description
        else
          null;
      homepage =
        if fields ? homepage && builtins.isString fields.homepage then
          fields.homepage
        else
          null;
    in
    (pkgs.lib.optionalAttrs (mappedLicense != null) { license = mappedLicense; })
    // (pkgs.lib.optionalAttrs (description != null) { inherit description; })
    // (pkgs.lib.optionalAttrs (homepage != null) { inherit homepage; });
  withSourceMeta =
    sourceName: drv:
    let
      overrides = metaOverridesFromFields (sourceFieldsFor sourceName);
    in
    if overrides == { } then
      drv
    else
      drv.overrideAttrs (old: {
        meta =
          (old.meta or { })
          // overrides;
      });
  callPackageWithSourceMeta =
    path: sourceName: args:
    withSourceMeta sourceName (pkgs.callPackage path (args // { source = sources.${sourceName}; }));
  libz-rs-sys-cdylib = callPackageWithSourceMeta ./zlib-rs/libz-rs-sys-cdylib "zlib-rs" { };
in
{
  errorformat = callPackageWithSourceMeta ./errorformat "errorformat" { };
  gogcli = callPackageWithSourceMeta ./gogcli "gogcli" { sourceMeta = sourceMetaFor "gogcli"; };
  starlink-exporter = callPackageWithSourceMeta ./starlink-exporter "starlink-exporter" { };
  kubernetes-mcp-server = callPackageWithSourceMeta ./kubernetes-mcp-server "kubernetes-mcp-server" {
    sourceMeta = sourceMetaFor "kubernetes-mcp-server";
  };
  gitbucket = callPackageWithSourceMeta ./gitbucket "gitbucket" { };
  prometheus-jmx-exporter = callPackageWithSourceMeta ./prometheus-jmx-exporter "prometheus-jmx-exporter" { };
  codex-bin =
    let
      sourceName = "codex-${system}-bin";
    in
    if builtins.hasAttr sourceName sources then
      withSourceMeta sourceName (
        pkgs.callPackage ./codex-bin {
          source = sources.${sourceName};
          zlib = libz-rs-sys-cdylib;
        }
      )
    else
      null;
  caddy = pkgs.callPackage ./caddy { };
  kakehashi = callPackageWithSourceMeta ./kakehashi "kakehashi" { };
  hev-socks5-server = callPackageWithSourceMeta ./hev-socks5-server "hev-socks5-server" {
    sourceMeta = sourceMetaFor "hev-socks5-server";
  };
  socks5shim = callPackageWithSourceMeta ./socks5shim "socks5shim" { };
  gf-cli = callPackageWithSourceMeta ./gf-cli "gf-cli" { };
  perl5-devel = callPackageWithSourceMeta ./perl5-devel "perl5" { };
  octorus = callPackageWithSourceMeta ./octorus "octorus" { };
  inherit libz-rs-sys-cdylib;

  apple-oss-distributions = import ./apple-oss-distributions {
    inherit callPackageWithSourceMeta;
  };
}
