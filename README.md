# johejo/nur-packages

**My personal [NUR](https://github.com/nix-community/NUR) repository**

![Build and populate cache](https://github.com/johejo/nur-packages/workflows/Build%20and%20populate%20cache/badge.svg)

[![Cachix Cache](https://img.shields.io/badge/cachix-johejo-blue.svg)](https://johejo.cachix.org)

## How to use

```nix
{
  # Add NUR to your inputs
  inputs.nur.url = "github:nix-community/NUR";

  # Then you can use it in your configuration
  # For example, using it as an overlay:
  outputs = { self, nixpkgs, nur, ... }: {
    nixosConfigurations.my-machine = nixpkgs.lib.nixosSystem {
      modules = [
        { nixpkgs.overlays = [ nur.overlay ]; }
        # Now you can use packages like:
        # environment.systemPackages = [ pkgs.nur.repos.johejo.example-package ];
      ];
    };
  };
}
```

## Packages

You can explore the packages in this repository using `nix flake show github:johejo/nur-packages`.

