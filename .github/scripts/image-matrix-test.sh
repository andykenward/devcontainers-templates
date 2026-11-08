#!/usr/bin/env bash
# Checks which releases image-matrix.sh builds and which tags each one gets.
# Run by `mise run lint`.
set -euo pipefail

matrix="$(dirname "$0")/image-matrix.sh"
# 1.1 and 1.10 share a prefix, and 1.9 sorts before 1.10.
releases=$'image-v1.1.0\nimage-v1.2.0\nimage-v1.9.0\nimage-v1.10.0\nimage-v2.0.0'
d=2026-01-05
entry() { printf '{"tag":"image-v%s","version":"%s","major":"%s","tags":"%s"}' "$1" "$1" "${1%%.*}" "$2"; }

failures=0
# expect <label> <want> <releases> [tag]
expect() {
  local label="$1" want="$2" input="$3" got
  shift 3
  got="$(DATE="$d" "$matrix" "$@" <<<"$input" 2>/dev/null)" || got="exit $?"
  if [ "$got" = "$want" ]; then
    echo "✅ $label"
  else
    echo "❌ $label"; echo "   want: $want"; echo "   got:  $got"; failures=$((failures + 1))
  fi
}

expect "newest of the two highest majors" \
  "[$(entry 1.10.0 "1.10.0,1.10.0-$d,1.10,1"),$(entry 2.0.0 "2.0.0,2.0.0-$d,2.0,2,latest")]" "$releases"
expect "an older minor keeps only its own tags" \
  "[$(entry 1.9.0 "1.9.0,1.9.0-$d,1.9")]" "$releases" image-v1.9.0
expect "1.1. doesn't match 1.10" \
  "[$(entry 1.1.0 "1.1.0,1.1.0-$d,1.1")]" "$releases" image-v1.1.0
expect "newest overall gets latest" \
  "[$(entry 2.0.0 "2.0.0,2.0.0-$d,2.0,2,latest")]" "$releases" image-v2.0.0
expect "unknown tag fails" "exit 1" "$releases" image-v3.0.0
expect "no releases builds nothing" "[]" ""

if [ "$failures" -gt 0 ]; then
  echo "$failures check(s) failed"; exit 1
fi
