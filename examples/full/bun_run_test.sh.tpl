#!/usr/bin/env bash
set -euo pipefail

self="$0"
runfiles_dir="${RUNFILES_DIR:-}"
manifest="${RUNFILES_MANIFEST_FILE:-}"

if [[ -n "$runfiles_dir" && -d "$runfiles_dir" ]]; then
  :
elif [[ -d "${self}.runfiles" ]]; then
  runfiles_dir="${self}.runfiles"
elif [[ -n "$manifest" && -f "$manifest" ]]; then
  :
elif [[ -f "${self}.runfiles_manifest" ]]; then
  manifest="${self}.runfiles_manifest"
else
  echo "bun_run_test: unable to locate runfiles for $self" >&2
  exit 1
fi

rlocation() {
  local path="$1"
  if [[ -n "$runfiles_dir" ]]; then
    local candidate="${runfiles_dir}/${path}"
    if [[ -e "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  fi

  if [[ -z "$manifest" ]]; then
    echo "bun_run_test: missing runfile $path" >&2
    exit 1
  fi

  local result=""
  while IFS= read -r line; do
    case "$line" in
      "$path "*)
        result="${line#"$path "}"
        break
        ;;
    esac
  done < "$manifest"
  if [[ -z "$result" ]]; then
    echo "bun_run_test: missing runfile $path" >&2
    exit 1
  fi
  printf '%s\n' "$result"
}

workspace="$(dirname "$(rlocation "{{PACKAGE_JSON_PATH}}")")"
bun="$(rlocation "{{BUN_PATH}}")"
node="$(rlocation "{{NODE_PATH}}")"
{{RUNFILES_ENV}}

cd "$workspace"

export BUN_INSTALL_NO_TRACK=1
export DO_NOT_TRACK=1
export NO_COLOR=1
export HOME="${TEST_TMPDIR:-/tmp}"
export XDG_CACHE_HOME="${TEST_TMPDIR:-/tmp}/.cache"
export PATH="$(dirname "$node"):$(dirname "$bun"):${workspace}/node_modules/.bin:${PATH}"

exec "$bun" run {{SCRIPT}} {{ARGS}}
