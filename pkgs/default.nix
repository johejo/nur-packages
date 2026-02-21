{ pkgs, system }:
let
  sources = pkgs.callPackage ../_sources/generated.nix { };
  sourceMeta = (builtins.fromJSON (builtins.readFile ../_sources/meta.json)).packages;
  sourceMetaFor = sourceName: sourceMeta.${sourceName} or { };
  sourceFieldsFor =
    sourceName:
    let
      pkgMeta = sourceMetaFor sourceName;
    in
    if builtins.isAttrs pkgMeta && pkgMeta ? fields && builtins.isAttrs pkgMeta.fields then
      pkgMeta.fields
    else
      { };
  getSourceMeta = sourceMetaFor;
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
      mapped = map (spdx: licensesBySpdxId.${spdx} or null) tokens;
      uniqueLicenses = pkgs.lib.unique mapped;
    in
    if tokens == [ ] || !(builtins.all (license: license != null) mapped) then
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
    in
    (if mappedLicense != null then { license = mappedLicense; } else { })
    // (if fields ? description then { description = fields.description; } else { })
    // (if fields ? homepage then { homepage = fields.homepage; } else { });
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
  gogcli = callPackageWithSourceMeta ./gogcli "gogcli" { sourceMeta = getSourceMeta "gogcli"; };
  starlink-exporter = callPackageWithSourceMeta ./starlink-exporter "starlink-exporter" { };
  kubernetes-mcp-server = callPackageWithSourceMeta ./kubernetes-mcp-server "kubernetes-mcp-server" {
    sourceMeta = getSourceMeta "kubernetes-mcp-server";
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
    sourceMeta = getSourceMeta "hev-socks5-server";
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
