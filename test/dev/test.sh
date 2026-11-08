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

# Starship prompt in both shells: the image's config by default, the project's
# .devcontainer/starship.toml (the template's DEVCONTAINER_STARSHIP_CONFIG)
# whenever it exists. Prints "starship-config=<config>" only when Starship is
# running, so other rc output can't be mistaken for the result.
# shellcheck disable=SC2016 # expand inside the interactive shell
starship_in() {
  "$1" -ic '[ "$STARSHIP_SHELL" = "$0" ] && echo "starship-config=${STARSHIP_CONFIG:-default}"' "$1" 2>/dev/null |
    grep -o 'starship-config=.*'
}
starship_config_is() { [ "$(starship_in "$1")" = "starship-config=$2" ]; }
project_config_path() { echo "${DEVCONTAINER_STARSHIP_CONFIG:?template sets DEVCONTAINER_STARSHIP_CONFIG}"; }
project_starship_config() {
  local f ok
  f="$(project_config_path)" || return 1
  [ ! -e "$f" ] || return 1 # the template ships no project config
  echo 'add_newline = true' > "$f"
  starship_config_is zsh "$f" && starship_config_is bash "$f"; ok=$?
  rm -f "$f"
  return "$ok"
}
# A shell started before the project file existed passes the project path on:
# a child shell started after the file is created uses it.
# shellcheck disable=SC2016 # expand inside the shells
project_config_reaches_child_shell() {
  local f ok
  f="$(project_config_path)" || return 1
  [ ! -e "$f" ] || return 1
  F="$f" zsh -ic 'echo "add_newline = true" > "$F"; zsh -ic "echo starship-config=\${STARSHIP_CONFIG:-default}"' 2>/dev/null |
    grep -qx "starship-config=$f"; ok=$?
  rm -f "$f"
  return "$ok"
}
# Starship exits 0 even when it can't parse its config; it reports problems as
# ERROR or WARN on stderr. Run in an empty folder so no module times out.
image_starship_config_valid() {
  local config="$HOME/.config/starship.toml" dir errors
  [ -r "$config" ] || return 1
  dir="$(mktemp -d)"
  errors="$(cd "$dir" && STARSHIP_CONFIG="$config" starship prompt 2>&1 >/dev/null)"
  rmdir "$dir"
  [ -z "$errors" ] || { echo "$errors"; return 1; }
}
check "starship" starship --version
check "starship outside the mise volume" test "$(command -v starship)" = /usr/local/bin/starship
check "starship prompt in zsh, image config"  starship_config_is zsh default
check "starship prompt in bash, image config" starship_config_is bash default
check "image starship config is valid" image_starship_config_valid
check "project starship config replaces it" project_starship_config
check "project starship config reaches child shells" project_config_reaches_child_shell

for dir in "$HOME/.claude" "$HOME/.config/gh" "$HOME/.config/git" "$HOME/.local/share/mise" \
           "$HOME/.vscode-server/extensions" /commandhistory; do
  check "writable $dir" bash -c "touch '$dir/.write-test' && rm '$dir/.write-test'"
done

if [ "$failures" -gt 0 ]; then
  echo "$failures check(s) failed"; exit 1
fi
echo "All checks passed"
