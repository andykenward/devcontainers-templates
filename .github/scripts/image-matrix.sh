#!/usr/bin/env bash
# Prints the Build image matrix as JSON, one entry per release to build:
#   [{"tag":"image-v1.2.0","version":"1.2.0","major":"1","tags":"1.2.0,1.2.0-2026-11-07,1.2,1,latest"}, ...]
# With a tag, builds only that release; without, the newest release of each of
# the two highest majors. Each build gets its version and a dated tag, and a
# floating tag (X.Y, X, latest) only when it is the newest release that tag
# could point at, so rebuilding 1.2.0 after 1.3.0 can't roll `1` back.
#
# Usage: image-releases.sh | image-matrix.sh [image-vX.Y.Z]
#   Reads the releases (image-vX.Y.Z, oldest first) on stdin. DATE overrides
#   today's date (UTC) for the dated tag.
set -euo pipefail

tag="${1:-}"
date="${DATE:-$(date -u +%Y-%m-%d)}"
releases="$(cat)"

# The newest release whose version starts with $1: "1.2.", "1." or "" for any.
# A fixed-string match, so the dots are literal; every entry starts with
# image-v, which anchors the prefix.
newest() { grep -F "image-v$1" <<<"$releases" | tail -1 || true; }

if [ -n "$tag" ]; then
  if ! grep -qxF "$tag" <<<"$releases"; then
    echo "::error::'${tag}' is not an image release (image-vX.Y.Z tag)" >&2
    exit 1
  fi
  build="$tag"
else
  majors="$(for t in $releases; do version="${t#image-v}"; echo "${version%%.*}"; done | uniq | tail -2)"
  build=""
  for major in $majors; do
    build+="$(newest "${major}.")"$'\n'
  done
fi

# Plain printf is safe JSON: every value is digits, dots and dashes, since
# image-releases.sh only lets image-vX.Y.Z tags through.
sep=""
printf '['
for t in $build; do
  version="${t#image-v}"
  major="${version%%.*}"
  tags="${version},${version}-${date}"
  [ "$(newest "${version%.*}.")" = "$t" ] && tags+=",${version%.*}"
  [ "$(newest "${major}.")" = "$t" ] && tags+=",${major}"
  [ "$(newest "")" = "$t" ] && tags+=",latest"
  printf '%s{"tag":"%s","version":"%s","major":"%s","tags":"%s"}' "$sep" "$t" "$version" "$major" "$tags"
  sep=","
  echo "Building $t, tags: $tags" >&2
done
echo ']'
