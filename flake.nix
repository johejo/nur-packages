{
  description = "johejo's personal NUR repository";
  inputs.nixpkgs.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.zst";
  outputs =
    { self, nixpkgs, ... }:
    let
      supportedSystems = [
        "aarch64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      pkgsFor = system: import nixpkgs { inherit system; };
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
          allPackages = import ./pkgs { inherit pkgs system; };
        in
        nixpkgs.lib.filterAttrs (_: value: nixpkgs.lib.isDerivation value) allPackages
      );

      legacyPackages = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        import ./pkgs { inherit pkgs system; }
      );

      nixosModules = import ./nixosModules.nix { inherit self; };

      formatter = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        pkgs.nixfmt-tree.overrideAttrs (old: {
          env = (old.env or { }) // {
            configFile = toString ./.treefmt.toml;
          };
        })
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.mkShellNoCC {
            packages = with pkgs; [
              nixfmt
              (nix-update.overrideAttrs (old: {
                # Prefetch lazy flake sources only when missing (upstream PR #692).
                # Remove once nixpkgs includes the fix.
                patches = (old.patches or [ ]) ++ [
                  (fetchurl {
                    url = "https://github.com/Mic92/nix-update/commit/d545c1fad667e573128cad0db55fdc77134a4d3c.patch";
                    hash = "sha256-3iHlAZsv8wH2NCVGcOVh8S/MJY2gfmPHqgLsmPVIJ0U=";
                  })
                ];
              }))
              gh
              jq
            ];
          };
        }
      );
    };
}
