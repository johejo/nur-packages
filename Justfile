# Update one package through passthru.updateScript.
update package:
    nix-update {{ package }} --flake --use-update-script

# Update all nvfetcher sources and packages migrated to nix-update-script.
update-all:
    nvfetcher
    just update starlink-exporter
    just update socks5shim
    just update mise-bin
    nix-update scriptc --flake --no-src
