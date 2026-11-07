#!/usr/bin/env bash
# Run by the template's postCreateCommand after each (re)build.
set -euo pipefail

uid="$(id -u)"
gid="$(id -g)"

# Volumes created by an older image, or before updateRemoteUserUID changed the
# user's UID, may be owned by someone else. Fix ownership so tools can write.
for dir in \
  "${CLAUDE_CONFIG_DIR:-$HOME/.claude}" \
  "$HOME/.config/gh" \
  "${MISE_DATA_DIR:-$HOME/.local/share/mise}" \
  "$HOME/.vscode-server/extensions" \
  /commandhistory; do
  if [ -d "$dir" ] && [ "$(stat -c %u "$dir")" != "$uid" ]; then
    echo "Fixing ownership of $dir"
    sudo chown -R "$uid:$gid" "$dir"
  fi
done

# Install the global tools (e.g. a newer Node LTS than the shared volume has)
# plus anything the project declares in mise.toml / .tool-versions / .nvmrc.
if command -v mise >/dev/null 2>&1; then
  mise trust --yes --quiet . 2>/dev/null || true
  mise install --yes
  mise reshim
fi

# Let git use gh's credentials when gh is logged in.
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  gh auth setup-git
fi
