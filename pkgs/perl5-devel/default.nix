{
  lib,
  perl,
  source,
  ...
}:

perl.overrideAttrs (old: {
  version = lib.removePrefix "v" source.version;
  src = source.src;
  configureFlags = (old.configureFlags or [ ]) ++ [
    "-Dusedevel"
  ];
})
