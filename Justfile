# Update one package through passthru.updateScript.
update package:
    #!/usr/bin/env sh
    set -eu
    export NIXPKGS_ALLOW_UNFREE=1
    export NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1
    targets="$(nix eval --impure --raw --file ./lib/update-targets.nix)"
    system="$(printf '%s\n' "$targets" | awk -F '\t' -v package='{{ package }}' '$2 == package { print $1; exit }')"
    if [ -z "$system" ]; then
        echo "No package with passthru.updateScript: {{ package }}" >&2
        exit 1
    fi
    nix-update {{ package }} --flake --use-update-script --system="$system"

# Update all locally versioned packages through passthru.updateScript.
update-all:
    #!/usr/bin/env sh
    set -eu
    export NIXPKGS_ALLOW_UNFREE=1
    export NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1
    nix eval --impure --raw --file ./lib/update-targets.nix |
        while IFS="$(printf '\t')" read -r system package; do
            nix-update "$package" --flake --use-update-script --system="$system"
        done
