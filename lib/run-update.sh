#!/usr/bin/env sh
set -eu

system="$1"
package="$2"
current_system="$(nix eval --impure --raw --expr builtins.currentSystem)"

if [ "$system" = "$current_system" ]; then
    nix-update "$package" --flake --use-update-script --system="$system"
    exit
fi

update_script="$(
    nix eval --impure --json \
        ".#packages.$system.$package.passthru.updateScript"
)"

if ! printf '%s' "$update_script" |
    jq -e 'type == "array" and length > 0 and (.[0] | endswith("/bin/nix-update"))' >/dev/null; then
    echo "Cannot run non-nix-update updateScript for $package ($system) on $current_system" >&2
    exit 1
fi

printf '%s' "$update_script" |
    jq --raw-output0 '.[1:][]' |
    xargs -0 nix-update "$package" --flake
