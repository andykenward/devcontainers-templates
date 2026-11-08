# shellcheck shell=bash
# Sourced from ~/.bashrc and ~/.zshrc (added by the dev image).

# mise: activate for interactive shells (shims on PATH cover non-interactive use).
if command -v mise >/dev/null 2>&1; then
  if [ -n "${ZSH_VERSION:-}" ]; then
    eval "$(mise activate zsh)"
  elif [ -n "${BASH_VERSION:-}" ]; then
    eval "$(mise activate bash)"
  fi
fi

# Persistent shell history (the /commandhistory volume survives rebuilds).
if [ -d /commandhistory ] && [ -w /commandhistory ]; then
  if [ -n "${ZSH_VERSION:-}" ]; then
    HISTFILE=/commandhistory/.zsh_history
    HISTSIZE=100000
    # shellcheck disable=SC2034 # read by zsh
    SAVEHIST=100000
    setopt INC_APPEND_HISTORY 2>/dev/null || true
  elif [ -n "${BASH_VERSION:-}" ]; then
    HISTFILE=/commandhistory/.bash_history
    HISTSIZE=100000
    HISTFILESIZE=100000
    shopt -s histappend
    case "${PROMPT_COMMAND:-}" in
      *"history -a"*) ;;
      *) PROMPT_COMMAND="history -a${PROMPT_COMMAND:+; $PROMPT_COMMAND}" ;;
    esac
  fi
fi

# Starship prompt, the same in bash and zsh, replacing the base image's prompt.
# The image's config (~/.config/starship.toml) updates with image releases. A
# project can replace it: the template sets DEVCONTAINER_STARSHIP_CONFIG to the
# project's .devcontainer/starship.toml, used whenever that file exists.
# Checked in every new shell (child shells and `exec zsh` too), so creating or
# deleting the file applies to the next one. Starship can't merge configs, so
# start a project file from a copy of the image's.
if [ -n "${DEVCONTAINER_STARSHIP_CONFIG:-}" ]; then
  if [ -r "$DEVCONTAINER_STARSHIP_CONFIG" ]; then
    export STARSHIP_CONFIG="$DEVCONTAINER_STARSHIP_CONFIG"
  elif [ "${STARSHIP_CONFIG:-}" = "$DEVCONTAINER_STARSHIP_CONFIG" ]; then
    unset STARSHIP_CONFIG
  fi
fi
# Use the image's binary by path: the mise shims come first on PATH, and a
# starship shim left on the shared mise volume (from a mise install that no
# config uses any more) fails instead of falling through to this one. The init
# script calls Starship by the path it was started from.
devcontainer_starship=/usr/local/bin/starship
[ -x "$devcontainer_starship" ] || devcontainer_starship="$(command -v starship 2>/dev/null)"
if [ -n "$devcontainer_starship" ]; then
  if [ -n "${ZSH_VERSION:-}" ]; then
    eval "$("$devcontainer_starship" init zsh)"
  elif [ -n "${BASH_VERSION:-}" ]; then
    eval "$("$devcontainer_starship" init bash)"
  fi
fi
unset devcontainer_starship
