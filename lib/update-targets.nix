let
  flake = builtins.getFlake (toString ./..);
  lib = flake.inputs.nixpkgs.lib;
  system = builtins.currentSystem;
  packages = flake.packages.${system} or { };
  availableOnHost = lib.meta.availableOn { inherit system; };
  targets = lib.filterAttrs (
    _: package: package.passthru ? updateScript && availableOnHost package
  ) packages;
in
lib.mapAttrs (_: _: system) targets
