# Wrap a Node.js CLI entrypoint so it runs under Deno with narrow permissions.
#
# usage: makeDenoNodeWrapper --package-root DIR --entry FILE --bin NAME...
#          [--env-prefix PREFIX]... [--allow-env NAME]... [--allow-run PROG]...
#          [-- MAKE_WRAPPER_ARGS...]
#
# Environment access is limited to names found by extract-node-env, the
# runtime-level names below, and any --allow-env additions. debug's
# environment enumeration is patched so it stays within that allowlist.
makeDenoNodeWrapper() {
  local packageRoot="" entry=""
  local -a bins=() prefixArgs=() extraEnv=() allowRun=() wrapperArgs=()

  while (( $# > 0 )); do
    case "$1" in
      --package-root) packageRoot="$2"; shift 2 ;;
      --entry) entry="$2"; shift 2 ;;
      --bin) bins+=("$2"); shift 2 ;;
      --env-prefix) prefixArgs+=(--include-literal-prefix "$2"); shift 2 ;;
      --allow-env) extraEnv+=("$2"); shift 2 ;;
      --allow-run) allowRun+=("$2"); shift 2 ;;
      --) shift; wrapperArgs=("$@"); break ;;
      *) echo "makeDenoNodeWrapper: unknown argument: $1" >&2; return 2 ;;
    esac
  done

  if [[ -z "$packageRoot" || -z "$entry" || ${#bins[@]} -eq 0 ]]; then
    echo "makeDenoNodeWrapper: --package-root, --entry and --bin are required" >&2
    return 2
  fi

  # Read by the runtime or Deno's Node compatibility layer, not by package code.
  extraEnv+=(
    TMPDIR TMP TEMP
    HTTP_PROXY HTTPS_PROXY ALL_PROXY NO_PROXY
    http_proxy https_proxy all_proxy no_proxy
    NODE_USE_SYSTEM_CA
  )

  local -a debugFiles=()
  mapfile -t debugFiles < <(find "$packageRoot/node_modules" -path '*/debug/src/node.js' 2>/dev/null)
  local debugEnv='[]'
  if (( ${#debugFiles[@]} > 0 )); then
    debugEnv="$(@patchDebugEnv@ --format json "${debugFiles[@]}")"
  fi

  local allowEnv
  allowEnv="$(
    @extractNodeEnv@ --format json "${prefixArgs[@]}" "$packageRoot" |
      @jq@ -r \
        --args \
        --argjson debug "$debugEnv" \
        '. + $debug + $ARGS.positional | unique | join(",")' \
        "${extraEnv[@]}"
  )"
  echo "makeDenoNodeWrapper: allowing environment variables: $allowEnv"

  local -a denoFlags=(
    --allow-read
    --allow-write
    --allow-net
    --allow-sys=homedir,uid,ca
    "--allow-env=$allowEnv"
  )
  if (( ${#allowRun[@]} > 0 )); then
    denoFlags+=("--allow-run=$(IFS=,; echo "${allowRun[*]}")")
  fi

  local bin flag
  local -a flagArgs=()
  for flag in run "${denoFlags[@]}" "$entry"; do
    flagArgs+=(--add-flags "$flag")
  done
  for bin in "${bins[@]}"; do
    # npm installs bins as symlinks into the package; writing through one
    # would clobber the entrypoint.
    rm -f "$out/bin/$bin"
    makeWrapper @deno@ "$out/bin/$bin" \
      --set DENO_NO_UPDATE_CHECK 1 \
      "${wrapperArgs[@]}" \
      "${flagArgs[@]}"
  done
}
