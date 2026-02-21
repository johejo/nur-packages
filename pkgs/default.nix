{ pkgs, system }:
let
  lib = pkgs.lib;
  sources = pkgs.callPackage ../_sources/generated.nix { };
  sourceMeta = (builtins.fromJSON (builtins.readFile ../_sources/meta.json)).packages;
  sourceMetaFor =
    sourceName:
    let
      meta = sourceMeta.${sourceName} or { };
    in
    if builtins.isAttrs meta then meta else { };
  sourceFieldsFor =
    sourceName:
    let
      fields = lib.attrByPath [ sourceName "fields" ] { } sourceMeta;
    in
    if builtins.isAttrs fields then fields else { };
  tokenizeSpdxExpression =
    value:
    lib.filter (token: token != "") (
      map lib.strings.trim (
        lib.splitString "|" (builtins.replaceStrings [ " OR " " AND " ] [ "|" "|" ] value)
      )
    );
  licensesBySpdxId = builtins.listToAttrs (
    map
      (license: {
        name = license.spdxId;
        value = license;
      })
      (
        lib.filter (
          license:
          builtins.isAttrs license
          && license ? spdxId
          && builtins.isString license.spdxId
          && license.spdxId != ""
        ) (builtins.attrValues lib.licenses)
      )
  );
  licenseFromSpdxExpression =
    value:
    let
      tokens = tokenizeSpdxExpression value;
      mappedKnown = lib.filter (license: license != null) (
        map (spdx: licensesBySpdxId.${spdx} or null) tokens
      );
      uniqueLicenses = lib.unique mappedKnown;
    in
    if uniqueLicenses == [ ] then
      null
    else if builtins.length uniqueLicenses == 1 then
      builtins.head uniqueLicenses
    else
      uniqueLicenses;
  stringFieldOrNull =
    fields: name:
    if builtins.hasAttr name fields && builtins.isString (builtins.getAttr name fields) then
      builtins.getAttr name fields
    else
      null;
  metaOverridesFromFields =
    fields:
    let
      mappedLicense =
        if fields ? licenseSpdx && builtins.isString fields.licenseSpdx then
          licenseFromSpdxExpression fields.licenseSpdx
        else
          null;
    in
    lib.filterAttrs (_: value: value != null) {
      license = mappedLicense;
      description = stringFieldOrNull fields "description";
      homepage = stringFieldOrNull fields "homepage";
    };
  withSourceMeta =
    sourceName: drv:
    let
      overrides = metaOverridesFromFields (sourceFieldsFor sourceName);
    in
    if overrides == { } then
      drv
    else
      drv.overrideAttrs (old: {
        meta = (old.meta or { }) // overrides;
      });
  callPackageWithSourceMeta =
    path: sourceName: args:
    withSourceMeta sourceName (pkgs.callPackage path (args // { source = sources.${sourceName}; }));
  callPackageWithSourceMetaArg =
    path: sourceName: args:
    callPackageWithSourceMeta path sourceName (args // { sourceMeta = sourceMetaFor sourceName; });
  libz-rs-sys-cdylib = callPackageWithSourceMeta ./zlib-rs/libz-rs-sys-cdylib "zlib-rs" { };
in
{
  errorformat = callPackageWithSourceMeta ./errorformat "errorformat" { };
  gogcli = callPackageWithSourceMetaArg ./gogcli "gogcli" { };
  starlink-exporter = callPackageWithSourceMeta ./starlink-exporter "starlink-exporter" { };
  kubernetes-mcp-server =
    callPackageWithSourceMetaArg ./kubernetes-mcp-server "kubernetes-mcp-server"
      { };
  gitbucket = callPackageWithSourceMeta ./gitbucket "gitbucket" { };
  prometheus-jmx-exporter =
    callPackageWithSourceMeta ./prometheus-jmx-exporter "prometheus-jmx-exporter"
      { };
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
  hev-socks5-server = callPackageWithSourceMetaArg ./hev-socks5-server "hev-socks5-server" { };
  socks5shim = callPackageWithSourceMeta ./socks5shim "socks5shim" { };
  gf-cli = callPackageWithSourceMeta ./gf-cli "gf-cli" { };
  perl5-devel = callPackageWithSourceMeta ./perl5-devel "perl5" { };
  octorus = callPackageWithSourceMeta ./octorus "octorus" { };
  inherit libz-rs-sys-cdylib;

  apple-oss-distributions = import ./apple-oss-distributions {
    inherit callPackageWithSourceMeta;
  };
}
