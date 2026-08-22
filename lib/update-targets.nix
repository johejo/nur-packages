let
  flake = builtins.getFlake (toString ./..);
  systems = builtins.attrNames flake.packages;
  orderedSystems =
    if builtins.elem builtins.currentSystem systems then
      [ builtins.currentSystem ] ++ builtins.filter (system: system != builtins.currentSystem) systems
    else
      systems;
  hasUpdateScript = system: package: flake.packages.${system}.${package}.passthru ? updateScript;
  targetsFor =
    system:
    map (package: {
      name = package;
      value = system;
    }) (builtins.filter (hasUpdateScript system) (builtins.attrNames flake.packages.${system}));
in
# The first duplicate wins, so orderedSystems also defines the preferred system.
builtins.listToAttrs (builtins.concatMap targetsFor orderedSystems)
