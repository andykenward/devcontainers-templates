#!/usr/bin/env bash
# Applies a template (with its default options) to a temp workspace, starts it
# with the devcontainer CLI, runs test/<id>/test.sh, then rebuilds the container
# and checks that data in the persisted volumes survived.
#
# Usage: .github/scripts/test-template.sh <template-id>
set -euo pipefail

id="${1:?template id required}"
root="$(cd "$(dirname "$0")/../.." && pwd)"
src="$root/src/$id"
workspace="$(mktemp -d)"
trap 'devcontainer_cleanup' EXIT

devcontainer_cleanup() {
  docker ps -aq --filter "label=devcontainer.local_folder=$workspace" | xargs -r docker rm -f >/dev/null 2>&1 || true
  rm -rf "$workspace"
}

cp -R "$src/." "$workspace/"
# mktemp -d is 0700; the container user may have a different UID (e.g. when run as root).
chmod 755 "$workspace"
rm -f "$workspace/devcontainer-template.json" "$workspace/README.md" "$workspace/NOTES.md"
mkdir -p "$workspace/test-project"
cp -R "$root/test/$id/." "$workspace/test-project/"

# Substitute ${templateOption:x} with each option's default, except the image
# tag: the test runs against the image built locally as :local (override with
# IMAGE_TAG), not a published one.
config="$workspace/.devcontainer/devcontainer.json"
while IFS=$'\t' read -r name default; do
  [ "$name" = imageVariant ] && default="${IMAGE_TAG:-local}"
  sed -i "s|\${templateOption:$name}|$default|g" "$config"
done < <(jq -r '.options // {} | to_entries[] | [.key, (.value.default | tostring)] | @tsv' "$src/devcontainer-template.json")

# Use a throwaway volume prefix so CI never touches real shared volumes.
prefix="test-$id-$$"
sed -i "s|source=devcontainer-|source=$prefix-|g" "$config"

echo "--- devcontainer.json under test"
cat "$config"

up() { devcontainer up --workspace-folder "$workspace" "$@"; }
exec_in() { devcontainer exec --workspace-folder "$workspace" "$@"; }

up
exec_in bash ./test-project/test.sh
# shellcheck disable=SC2016 # expand inside the container, not here
exec_in bash -c 'echo persisted > "$CLAUDE_CONFIG_DIR/.persist-test" && echo persisted > /commandhistory/.persist-test'

echo "--- rebuilding container to check persistence"
up --remove-existing-container
# shellcheck disable=SC2016 # expand inside the container, not here
exec_in bash -c 'grep -q persisted "$CLAUDE_CONFIG_DIR/.persist-test" && grep -q persisted /commandhistory/.persist-test'
echo "✅ volumes persisted across rebuild"

devcontainer_cleanup
docker volume ls -q | grep -E "^$prefix-" | xargs -r docker volume rm >/dev/null
