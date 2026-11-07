#!/usr/bin/env bash
# Runs inside a container created from the dev template.
set -uo pipefail

failures=0
check() {
  local label="$1"; shift
  if output="$("$@" 2>&1)"; then
    echo "✅ $label: ${output%%$'\n'*}"
  else
    echo "❌ $label"; echo "$output"; failures=$((failures + 1))
  fi
}

# Non-interactive login shell, like VS Code tasks and Claude Code's Bash tool.
check "mise"   mise --version
check "node"   node --version
check "npm"    npm --version
check "claude" claude --version
check "gh"     gh --version
check "zizmor" zizmor --version
check "node via interactive zsh"  zsh -ic 'node --version'
check "node via interactive bash" bash -ic 'node --version'
check "CLAUDE_CONFIG_DIR is set" test "${CLAUDE_CONFIG_DIR:-}" = "$HOME/.claude"

for dir in "$HOME/.claude" "$HOME/.config/gh" "$HOME/.local/share/mise" \
           "$HOME/.vscode-server/extensions" /commandhistory; do
  check "writable $dir" bash -c "touch '$dir/.write-test' && rm '$dir/.write-test'"
done

if [ "$failures" -gt 0 ]; then
  echo "$failures check(s) failed"; exit 1
fi
echo "All checks passed"
