#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(
  cd "$(dirname "${BASH_SOURCE[0]}")" && pwd
)"
cd "$ROOT_DIR"

RULES_FILE="$ROOT_DIR/meta-rules.json"
OUT_FILE="$ROOT_DIR/_sources/meta.json"
NVFETCHER_FILE="$ROOT_DIR/nvfetcher.toml"
GENERATED_JSON_FILE="$ROOT_DIR/_sources/generated.json"
FILTER_REGEX=""

usage() {
  cat <<'EOF'
Usage: ./update-source-meta.sh [options]

Options:
  --filter <regex>     Process only package names matching regex
  --rules <path>       Rules file path (default: meta-rules.json)
  --out <path>         Output path (default: _sources/meta.json)
  -h, --help           Show this help
EOF
}

need_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "error: required command not found: $cmd" >&2
    exit 1
  fi
}

nix_escape() {
  sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --filter)
      FILTER_REGEX="${2:-}"
      shift 2
      ;;
    --rules)
      RULES_FILE="${2:-}"
      shift 2
      ;;
    --out)
      OUT_FILE="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

need_cmd awk
need_cmd jq
need_cmd nix

if [[ ! -f "$NVFETCHER_FILE" ]]; then
  echo "error: nvfetcher.toml not found: $NVFETCHER_FILE" >&2
  exit 1
fi

if [[ ! -f "$RULES_FILE" ]]; then
  echo "error: rules file not found: $RULES_FILE" >&2
  exit 1
fi

if [[ ! -f "$GENERATED_JSON_FILE" ]]; then
  echo "error: generated source file not found: $GENERATED_JSON_FILE" >&2
  echo "hint: run nvfetcher first" >&2
  exit 1
fi

mapfile -t NVFETCHER_PACKAGES < <(
  awk '/^\[[^][]+\]$/ { print substr($0, 2, length($0)-2) }' "$NVFETCHER_FILE"
)

if [[ ${#NVFETCHER_PACKAGES[@]} -eq 0 ]]; then
  echo "error: no package sections were found in $NVFETCHER_FILE" >&2
  exit 1
fi

declare -A NVFETCHER_SET=()
for pkg in "${NVFETCHER_PACKAGES[@]}"; do
  NVFETCHER_SET["$pkg"]=1
done

while IFS= read -r configured_pkg; do
  if [[ -z "${NVFETCHER_SET[$configured_pkg]:-}" ]]; then
    echo "warning: package '$configured_pkg' exists in rules but not in nvfetcher.toml; skipping" >&2
  fi
done < <(jq -r '.packages | keys[]' "$RULES_FILE")

PACKAGES_JSON='{}'
PROCESSED=0
SKIPPED=0

for pkg in "${NVFETCHER_PACKAGES[@]}"; do
  if [[ -n "$FILTER_REGEX" ]] && [[ ! "$pkg" =~ $FILTER_REGEX ]]; then
    continue
  fi

  rule_type="$(jq -r --arg pkg "$pkg" 'if .packages[$pkg] == null then "null" else (.packages[$pkg] | type) end' "$RULES_FILE")"
  if [[ "$rule_type" == "null" ]]; then
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  profile_name=""
  overrides='{}'
  if [[ "$rule_type" == "string" ]]; then
    profile_name="$(jq -r --arg pkg "$pkg" '.packages[$pkg]' "$RULES_FILE")"
  elif [[ "$rule_type" == "object" ]]; then
    profile_name="$(jq -r --arg pkg "$pkg" '.packages[$pkg].profile // empty' "$RULES_FILE")"
    overrides="$(jq -c --arg pkg "$pkg" '.packages[$pkg]' "$RULES_FILE")"
    if [[ -z "$profile_name" ]]; then
      echo "warning: package '$pkg' has object rule but no profile; skipping" >&2
      SKIPPED=$((SKIPPED + 1))
      continue
    fi
  else
    echo "warning: package '$pkg' has unsupported rule type '$rule_type'; skipping" >&2
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  base_profile="$(jq -c --arg p "$profile_name" '.profiles[$p] // empty' "$RULES_FILE")"
  if [[ -z "$base_profile" ]]; then
    echo "warning: package '$pkg' references unknown profile '$profile_name'; skipping" >&2
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  rule="$(jq -c -n --argjson base "$base_profile" --argjson ov "$overrides" '$base * ($ov | del(.profile))')"
  file_rel="$(jq -r '.file // empty' <<<"$rule")"
  decode="$(jq -r '.decode // "text"' <<<"$rule")"
  query="$(jq -r '.query // ". // empty"' <<<"$rule")"
  if [[ -z "$file_rel" ]]; then
    echo "warning: package '$pkg' resolved rule has no file; skipping" >&2
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  echo "Processing $pkg..."
  src_out_path="$(
    nix build \
      --no-link \
      --print-out-paths \
      --impure \
      --expr "
        let
          flake = builtins.getFlake (toString ./.);
          pkgs = import flake.inputs.nixpkgs { system = builtins.currentSystem; };
          sources = pkgs.callPackage ./_sources/generated.nix { };
        in
          sources.\"$pkg\".src
      "
  )"

  source_file="$src_out_path/$file_rel"
  version="$(jq -r --arg pkg "$pkg" '.[$pkg].version // empty' "$GENERATED_JSON_FILE")"

  status="ok"
  description_json="null"
  if [[ ! -f "$source_file" ]]; then
    status="missing-file"
    echo "warning: package '$pkg' file not found: $source_file" >&2
  else
    decoded_json=""
    case "$decode" in
      json)
        decoded_json="$(cat "$source_file")"
        ;;
      toml)
        escaped_path="$(printf '%s' "$source_file" | nix_escape)"
        decoded_json="$(
          nix eval --json --impure --expr "
            builtins.fromTOML (builtins.readFile (builtins.toPath \"$escaped_path\"))
          "
        )"
        ;;
      text)
        decoded_json="$(jq -Rs '.' < "$source_file")"
        ;;
      *)
        status="unsupported-decode"
        echo "warning: package '$pkg' has unsupported decode: $decode" >&2
        ;;
    esac

    if [[ "$status" == "ok" ]]; then
      if extracted="$(jq -er "$query | if . == null then empty elif type == \"string\" then . else tostring end" <<<"$decoded_json" 2>/dev/null)"; then
        description_json="$(jq -Rn --arg s "$extracted" '$s')"
      else
        status="query-empty"
      fi
    fi
  fi

  entry="$(
    jq -n \
      --arg profile "$profile_name" \
      --arg version "$version" \
      --arg status "$status" \
      --arg file "$file_rel" \
      --arg decode "$decode" \
      --arg query "$query" \
      --arg src "$src_out_path" \
      --argjson description "$description_json" \
      '{
        profile: $profile,
        version: ($version | if . == "" then null else . end),
        description: $description,
        status: $status,
        source: {
          outPath: $src,
          file: $file,
          decode: $decode,
          query: $query
        }
      }'
  )"
  PACKAGES_JSON="$(jq -c --arg pkg "$pkg" --argjson e "$entry" '. + {($pkg): $e}' <<<"$PACKAGES_JSON")"
  PROCESSED=$((PROCESSED + 1))
done

mkdir -p "$(dirname "$OUT_FILE")"
tmp_file="$(mktemp)"
jq -n \
  --argjson packages "$PACKAGES_JSON" \
  '{ packages: $packages }' > "$tmp_file"
mv "$tmp_file" "$OUT_FILE"

echo "Wrote: $OUT_FILE"
echo "Processed: $PROCESSED, skipped: $SKIPPED"
