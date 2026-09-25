export NIXPKGS_ALLOW_UNFREE := "1"
export NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM := "1"

# Update one package through passthru.updateScript.
update package:
    #!/usr/bin/env sh
    set -eu
    system="$(nix eval --impure --json --file ./lib/update-targets.nix |
        jq -r --arg package "{{ package }}" '.[$package] // empty')"
    if [ -z "$system" ]; then
        echo "No updateable package for this system: {{ package }}" >&2
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

# After update*, build packages and commit tracked pkgs/ changes with version summaries.
commit-updates:
    #!/usr/bin/env sh
    set -eu
    if ! git diff --cached --quiet; then
        echo "Please commit or unstage existing staged changes first." >&2
        exit 1
    fi
    if git diff --quiet -- pkgs/; then
        echo "No package updates to commit."
        exit 0
    fi
    tmp_dir="$(mktemp -d)"
    trap 'rm -rf "$tmp_dir"' EXIT
    git diff --no-ext-diff --no-textconv --binary -- pkgs/ > "$tmp_dir/update.diff"
    nix build --no-link -f ci.nix cacheOutputs
    awk -f ./lib/update-commit-message.awk "$tmp_dir/update.diff" > "$tmp_dir/message"
    git diff --no-ext-diff --no-textconv --binary -- pkgs/ > "$tmp_dir/current.diff"
    if ! git diff --cached --quiet || ! cmp -s "$tmp_dir/update.diff" "$tmp_dir/current.diff"; then
        echo "Changes changed during the build or message generation; please rerun." >&2
        exit 1
    fi
    git add -u -- pkgs/
    git commit --file "$tmp_dir/message"
