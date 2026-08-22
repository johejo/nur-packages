{
  description = "johejo's personal NUR repository";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
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
              nix-update
              gh
            ];
          };
        }
      );
    };
}
