#!/usr/bin/env bash
# Prints the image releases (the image-v<X.Y.Z> tags) oldest first, one per
# line, for the workflows that build the image and release the template.
#
# Usage: .github/scripts/image-releases.sh   (needs gh, GH_TOKEN and GITHUB_REPOSITORY)
set -euo pipefail

# The endpoint returns every matching ref in one response today (checked
# against a repo with 971 tags); --paginate costs nothing and covers it if that
# changes. The call is kept apart from the filter so an API error fails the
# script; grep exiting 1 when there is no release yet is fine.
refs="$(gh api --paginate "repos/${GITHUB_REPOSITORY}/git/matching-refs/tags/image-v" --jq '.[].ref | sub("^refs/tags/"; "")')"
grep -E '^image-v[0-9]+\.[0-9]+\.[0-9]+$' <<<"$refs" | sort -V || true
