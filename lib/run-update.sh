#!/usr/bin/env sh
set -eu

system="$1"
package="$2"
current_system="$(nix eval --impure --raw --expr builtins.currentSystem)"

update_script="$(
    nix eval --impure --json \
        ".#packages.$system.$package.passthru.updateScript"
)"

if ! printf '%s' "$update_script" |
    jq -e 'type == "array" and length > 0 and (.[0] | endswith("/bin/nix-update"))' >/dev/null; then
    if [ "$system" = "$current_system" ]; then
        nix-update "$package" --flake --use-update-script --system="$system"
        exit
    fi
    echo "Cannot run non-nix-update updateScript for $package ($system) on $current_system" >&2
    exit 1
fi

printf '%s' "$update_script" |
    jq --raw-output0 '.[1:][]' |
    xargs -0 sh -eu -c '
        nix-update "$@"
        # A failed update may already have written the latest version. Force
        # hash updates even when the version is unchanged, keeping custom deps.
        nix-update "$@" --version=skip
    ' sh "$package" --flake --system="$system"
