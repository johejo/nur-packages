format=lines
prefixes=()
identifier_pattern='[A-Za-z_][A-Za-z0-9_]*'
identifier_regex="^${identifier_pattern}$"
uppercase_identifier_regex='^[A-Z][A-Z0-9_]*$'

while (( $# > 0 )); do
  case "$1" in
    --include-literal-prefix)
      if (( $# < 2 )); then
        echo "extract-node-env: $1 requires an argument" >&2
        exit 2
      fi
      if [[ ! "$2" =~ $identifier_regex ]]; then
        echo "extract-node-env: invalid environment name or prefix: $2" >&2
        exit 2
      fi
      prefixes+=("$2")
      shift 2
      ;;
    --format)
      if (( $# < 2 )) || [[ "$2" != lines && "$2" != json ]]; then
        echo "extract-node-env: --format must be 'lines' or 'json'" >&2
        exit 2
      fi
      format="$2"
      shift 2
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "extract-node-env: unknown option: $1" >&2
      exit 2
      ;;
    *)
      break
      ;;
  esac
done

if (( $# == 0 )); then
  echo "usage: extract-node-env [--format lines|json] [--include-literal-prefix PREFIX]... PATH..." >&2
  exit 2
fi

roots=("$@")
ast_grep_args=(
  --lang javascript
  --globs '*.js'
  --globs '*.cjs'
  --globs '*.mjs'
  --no-ignore parent
  --no-ignore vcs
)

run_ast_grep() {
  local status=0
  ast-grep run "${ast_grep_args[@]}" "$@" || status=$?
  if (( status > 1 )); then
    return "$status"
  fi
  return 0
}

scan_pattern() {
  local pattern="$1"
  shift
  run_ast_grep --json=stream --pattern "$pattern" "$@"
}

find_pattern_files() {
  local pattern="$1"
  shift
  run_ast_grep --files-with-matches --pattern "$pattern" "$@"
}

unquote_identifiers() {
  sed -nE "s/^([\"'])(${identifier_pattern})\\1$/\\2/p"
}

emit_member_names() {
  local object="$1"
  shift

  scan_pattern "$object.\$ENV" "$@" |
    jq -r '.metaVariables.single.ENV.text'

  scan_pattern "${object}[\$ENV]" "$@" |
    jq -r '.metaVariables.single.ENV.text' |
    unquote_identifiers
}

emit_destructured_names() {
  local declaration
  for declaration in const let var; do
    scan_pattern "$declaration { \$\$\$ENV } = process.env" "${roots[@]}" |
      jq -r '.metaVariables.multi.ENV[]?.text'
  done |
    sed -nE \
      "s/^[[:space:]]*(${identifier_pattern})([[:space:]]*[:=].*)?$/\\1/p"
}

emit_string_identifiers() {
  run_ast_grep --json=stream --kind string "$@" |
    jq -r '.text' |
    unquote_identifiers
}

emit_alias_files() {
  local declaration pattern
  for declaration in const let var; do
    for pattern in \
      "$declaration env = process.env" \
      "$declaration { env } = process"; do
      find_pattern_files "$pattern" "${roots[@]}"
    done
  done
}

emit_prefixed_literals() {
  local name prefix
  if (( ${#prefixes[@]} == 0 )); then
    return 0
  fi

  while IFS= read -r name; do
    for prefix in "${prefixes[@]}"; do
      if [[ "$name" == "$prefix"* ]]; then
        printf '%s\n' "$name"
        break
      fi
    done
  done < <(emit_string_identifiers "${roots[@]}")
}

collect_names() {
  emit_member_names process.env "${roots[@]}"
  emit_destructured_names

  while IFS= read -r file; do
    [[ -n "$file" ]] || continue
    emit_member_names env "$file"
    emit_string_identifiers "$file" |
      sed -nE "/$uppercase_identifier_regex/p"
  done < <(emit_alias_files | sort -u)

  emit_prefixed_literals
}

normalize_names() {
  sed -nE "/$identifier_regex/p" |
    sort -u
}

render_names() {
  if [[ "$format" == json ]]; then
    jq -Rsc 'split("\n") | map(select(length > 0))'
  else
    cat
  fi
}

collect_names |
  normalize_names |
  render_names
