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

# init: true in the image metadata puts an init process (tini) in front.
pid1_is_init() { case "$(cat /proc/1/comm)" in docker-init|tini) ;; *) cat /proc/1/comm; return 1 ;; esac; }
check "init process is PID 1" pid1_is_init

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

# The project's own config (test/dev/workspace, copied to the workspace root):
# postCreate trusts it and installs what it asks for.
node_major_is() { [ "$(node --version | cut -d. -f1)" = "v$1" ]; }
mise_installed() { mise which "$1" | grep -q "^${MISE_DATA_DIR:-$HOME/.local/share/mise}/installs/"; }
project_env_loaded() { mise env -s bash | grep -q 'DEVCONTAINER_TEST_ENV=trusted'; }
# Run here through `devcontainer exec`, whose environment comes from VS Code's
# kind of user env probe: the project's Node must win over the image's.
check "project .nvmrc picks the Node major" node_major_is "$(cat .nvmrc)"
# Terminal shells still activate mise (env, hooks); `script` gives them a tty.
# shellcheck disable=SC2016 # expand inside the shells
mise_activated_in_terminal() {
  script -qec "$1 -ic 'echo mise-shell=\$MISE_SHELL; node --version'" /dev/null |
    tr -d '\r' | grep -qx "mise-shell=$1" || return 1
  script -qec "$1 -ic 'node --version'" /dev/null | tr -d '\r' | grep -q "^v$(cat .nvmrc)\."
}
check "mise activated in a zsh terminal"  mise_activated_in_terminal zsh
check "mise activated in a bash terminal" mise_activated_in_terminal bash
check "project mise.toml tool installed"    mise_installed yq
check "project mise.toml tool runs"         yq --version
check "project config trusted (env loaded)" project_env_loaded

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
# A starship shim on the shared mise volume (left by a mise install no config
# uses) comes first on PATH and fails; the prompt must still start.
prompt_survives_stale_shim() {
  local shim="${MISE_DATA_DIR:-$HOME/.local/share/mise}/shims/starship" ok
  [ ! -e "$shim" ] || return 1
  printf '#!/bin/sh\necho "mise ERROR No version is set for shim: starship" >&2\nexit 1\n' > "$shim"
  chmod +x "$shim"
  starship_config_is zsh default && starship_config_is bash default; ok=$?
  rm -f "$shim"
  return "$ok"
}
check "starship" starship --version
check "starship outside the mise volume" test "$(command -v starship)" = /usr/local/bin/starship
check "starship prompt in zsh, image config"  starship_config_is zsh default
check "starship prompt in bash, image config" starship_config_is bash default
check "starship prompt despite a stale mise shim" prompt_survives_stale_shim
check "image starship config is valid" image_starship_config_valid
check "project starship config replaces it" project_starship_config
check "project starship config reaches child shells" project_config_reaches_child_shell

# A project config that mise can't install must not stop postCreate from
# installing Claude Code and setting up git. The warning proves mise really
# failed, so the test can't pass without reaching that branch.
post_create_survives_mise_failure() {
  local dir out ok
  dir="$(mktemp -d "$PWD/.broken-mise.XXXXXX")"
  printf '[tools]\n"aqua:devcontainer-test/does-not-exist" = "1.0.0"\n' > "$dir/mise.toml"
  out="$(cd "$dir" && devcontainer-post-create 2>&1)" &&
    grep -q 'WARNING: mise install failed' <<<"$out" && claude --version; ok=$?
  [ "$ok" -eq 0 ] || echo "$out"
  rm -rf "$dir"
  return "$ok"
}
check "postCreate continues after a failed mise install" post_create_survives_mise_failure

# With gh logged in and no SSH agent, postCreate sets gh up as git's
# credential helper. It must land in ~/.gitconfig, which each rebuild
# recreates, not in ~/.config/git/config on the shared volume. git writes
# --global there when ~/.gitconfig doesn't exist, as in this throwaway HOME.
# The fake gh reports a login and writes the helper the way gh does; the bad
# CLAUDE_CODE_VERSION skips the Claude Code download.
# shellcheck disable=SC2016 # expand inside the fake gh
gh_helper_stays_off_shared_volume() {
  local tmp ok
  tmp="$(mktemp -d)"
  mkdir -p "$tmp/bin" "$tmp/home/.config/git"
  : > "$tmp/home/.config/git/config"
  printf '#!/bin/sh\n[ "$1 $2" = "auth setup-git" ] && git config --global credential.helper gh-test\nexit 0\n' > "$tmp/bin/gh"
  chmod +x "$tmp/bin/gh"
  (cd "$tmp" && HOME="$tmp/home" PATH="$tmp/bin:$PATH" SSH_AUTH_SOCK='' CLAUDE_CODE_VERSION=0.0.0-none \
    devcontainer-post-create >/dev/null 2>&1)
  ! grep -q gh-test "$tmp/home/.config/git/config" && grep -q gh-test "$tmp/home/.gitconfig"; ok=$?
  rm -rf "$tmp"
  return "$ok"
}
check "gh credential helper stays off the shared git volume" gh_helper_stays_off_shared_volume

for dir in "$HOME/.claude" "$HOME/.config/gh" "$HOME/.config/git" "$HOME/.local/share/mise" \
           "$HOME/.vscode-server/extensions" /commandhistory; do
  check "writable $dir" bash -c "touch '$dir/.write-test' && rm '$dir/.write-test'"
done

if [ "$failures" -gt 0 ]; then
  echo "$failures check(s) failed"; exit 1
fi
echo "All checks passed"
