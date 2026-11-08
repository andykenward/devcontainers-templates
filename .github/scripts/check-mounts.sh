#!/usr/bin/env bash
# Checks that the repo's own dev container mounts the same volumes as the dev
# template (with the template's default volumePrefix), so the two can't drift.
#
# Usage: .github/scripts/check-mounts.sh
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
template="$root/src/dev/.devcontainer/devcontainer.json"
repo="$root/.devcontainer/devcontainer.json"
# Node (from mise.toml) rather than jq, which the lint runner may not have.
prefix="$(node -p 'require(process.argv[1]).options.volumePrefix.default' "$root/src/dev/devcontainer-template.json")"

# The mount strings, one per line. Both files are JSONC, so pick the quoted
# "source=..." entries out instead of parsing them.
mounts() { grep -o '"source=[^"]*"' "$1" | sort; }

if ! diff -u \
  --label "src/dev (volumePrefix=$prefix)" <(mounts "$template" | sed "s|\${templateOption:volumePrefix}|$prefix|g") \
  --label .devcontainer <(mounts "$repo"); then
  echo "❌ .devcontainer/devcontainer.json mounts differ from the dev template's" >&2
  exit 1
fi
echo "✅ .devcontainer mounts match the dev template"
