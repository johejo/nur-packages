{ pkgs, system }:
let
  lib = pkgs.lib;
  sources = pkgs.callPackage ../_sources/generated.nix { };
  sourceMeta = (builtins.fromJSON (builtins.readFile ../_sources/meta.json)).packages;
  sourceMetaFor = sourceName: sourceMeta.${sourceName} or { };
  sourceFieldsFor = sourceName: (sourceMetaFor sourceName).fields or { };
  stripSpdxWithException = token: builtins.head (lib.splitString " WITH " token);
  tokenizeSpdxExpression =
    value:
    lib.filter (token: token != "") (
      map (token: stripSpdxWithException (lib.strings.trim token)) (
        lib.splitString "|" (builtins.replaceStrings [ " OR " " AND " ] [ "|" "|" ] value)
      )
    );
  hasSpdxId = license: builtins.isString (license.spdxId or null) && license.spdxId != "";
  licensesBySpdxId = builtins.listToAttrs (
    map (license: lib.nameValuePair license.spdxId license) (
      lib.filter hasSpdxId (builtins.attrValues lib.licenses)
    )
  );
  licensesBySpdxIdLower = builtins.listToAttrs (
    map (license: lib.nameValuePair (lib.toLower license.spdxId) license) (
      lib.filter hasSpdxId (builtins.attrValues lib.licenses)
    )
  );
  lookupLicenseBySpdx =
    spdx: licensesBySpdxId.${spdx} or licensesBySpdxIdLower.${lib.toLower spdx} or null;
  licenseFromSpdxExpression =
    value:
    let
      tokens = tokenizeSpdxExpression value;
      mappedKnown = lib.filter (license: license != null) (map lookupLicenseBySpdx tokens);
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
      licenseSpdx = stringFieldOrNull fields "licenseSpdx";
      mappedLicense = if licenseSpdx != null then licenseFromSpdxExpression licenseSpdx else null;
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
  callPackageWithSystemSourceMeta =
    path: sourcePrefix: args:
    let
      sourceName = "${sourcePrefix}-${system}-bin";
    in
    if builtins.hasAttr sourceName sources then
      withSourceMeta sourceName (pkgs.callPackage path (args // { source = sources.${sourceName}; }))
    else
      null;
  libz-rs-sys-cdylib = callPackageWithSourceMeta ./zlib-rs/libz-rs-sys-cdylib "zlib-rs" { };
in
{
  alerter-bin = callPackageWithSourceMeta ./alerter-bin "alerter-bin" { };
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
  confluence-cli = callPackageWithSourceMeta ./confluence-cli "confluence-cli" { };
  codex-bin = callPackageWithSystemSourceMeta ./codex-bin "codex" { zlib = libz-rs-sys-cdylib; };
  libduckdb-bin = callPackageWithSystemSourceMeta ./libduckdb-bin "libduckdb" { };
  caddy = pkgs.callPackage ./caddy { };
  hev-socks5-server = callPackageWithSourceMetaArg ./hev-socks5-server "hev-socks5-server" { };
  hocage = callPackageWithSourceMeta ./hocage "hocage" { };
  socks5shim = callPackageWithSourceMeta ./socks5shim "socks5shim" { };
  gf-cli = callPackageWithSourceMeta ./gf-cli "gf-cli" { };
  perl5-devel = callPackageWithSourceMeta ./perl5-devel "perl5" { };
  kakehashi-bin = callPackageWithSystemSourceMeta ./kakehashi-bin "kakehashi" { };
  octorus-bin = callPackageWithSystemSourceMeta ./octorus-bin "octorus" { };
  gws-bin = callPackageWithSystemSourceMeta ./gws-bin "gws" { };
  displayplacer = callPackageWithSourceMeta ./displayplacer "displayplacer" { };
  inherit libz-rs-sys-cdylib;
  xremap-gnome = pkgs.callPackage ./xremap-gnome { };
}
