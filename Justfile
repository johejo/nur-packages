export NIXPKGS_ALLOW_UNFREE := "1"
export NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM := "1"

# Update one package through passthru.updateScript.
update package:
    #!/usr/bin/env sh
    set -eu
    system="$(nix eval --impure --json --file ./lib/update-targets.nix |
        jq -r --arg package "{{ package }}" '.[$package] // empty')"
    if [ -z "$system" ]; then
        echo "No package with passthru.updateScript: {{ package }}" >&2
        exit 1
    fi
    sh ./lib/run-update.sh "$system" "{{ package }}"

# Update all locally versioned packages through passthru.updateScript.
update-all: (update-all-parallel "1")

# Update all locally versioned packages in parallel.
update-all-parallel jobs="4":
    #!/usr/bin/env sh
    set -eu
    nix eval --impure --json --file ./lib/update-targets.nix |
        jq --raw-output0 'to_entries[] | .value, .key' |
        xargs -0 -n 2 -P "{{ jobs }}" sh ./lib/run-update.sh
