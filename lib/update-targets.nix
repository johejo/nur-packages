let
  flake = builtins.getFlake (toString ./..);
  systems = builtins.attrNames flake.packages;
  orderedSystems =
    if builtins.elem builtins.currentSystem systems then
      [ builtins.currentSystem ] ++ builtins.filter (system: system != builtins.currentSystem) systems
    else
      systems;
  hasUpdateScript =
    system: name:
    builtins.hasAttr name flake.packages.${system}
    && flake.packages.${system}.${name}.passthru ? updateScript;
  names = builtins.foldl' (
    result: system:
    builtins.foldl' (
      names: name:
      if hasUpdateScript system name && !builtins.elem name names then names ++ [ name ] else names
    ) result (builtins.attrNames flake.packages.${system})
  ) [ ] orderedSystems;
  targetFor =
    name:
    let
      system = builtins.head (builtins.filter (system: hasUpdateScript system name) orderedSystems);
    in
    "${system}\t${name}";
in
builtins.concatStringsSep "\n" (map targetFor names) + "\n"
