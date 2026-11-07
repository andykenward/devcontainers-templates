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

# mise hardening from the image's global config.
mise_setting_is() { [ "$(mise settings get "$1")" = "$2" ]; }
no_auto_trust() {
  [ -z "${MISE_TRUSTED_CONFIG_PATHS:-}" ] && mise_setting_is trusted_config_paths '[]'
}
# Like a repo cloned inside the project: under /workspaces, but not the
# workspace folder that postCreate trusts.
untrusted_config_ignored() {
  local dir; dir="$(mktemp -d "$PWD/.untrusted-test.XXXXXX")"
  printf '[env]\nUNTRUSTED_TEST = "loaded"\n' > "$dir/mise.toml"
  ! (cd "$dir" && MISE_YES=0 mise env -s bash 2>/dev/null | grep -q UNTRUSTED_TEST)
  local ok=$?
  rm -rf "$dir"
  return "$ok"
}
check "mise paranoid plugins"            mise_setting_is paranoid '["plugins"]'
check "mise asdf/vfox backends disabled" mise_setting_is disable_backends '["asdf", "vfox"]'
check "no auto-trusted config paths"     no_auto_trust
check "config outside the project is not trusted" untrusted_config_ignored

for dir in "$HOME/.claude" "$HOME/.config/gh" "$HOME/.local/share/mise" \
           "$HOME/.vscode-server/extensions" /commandhistory; do
  check "writable $dir" bash -c "touch '$dir/.write-test' && rm '$dir/.write-test'"
done

if [ "$failures" -gt 0 ]; then
  echo "$failures check(s) failed"; exit 1
fi
echo "All checks passed"
