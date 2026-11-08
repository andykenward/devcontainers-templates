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
# project can replace it: the template sets STARSHIP_CONFIG to the project's
# .devcontainer/starship.toml, used only when that file exists. Starship can't
# merge configs, so start a project file from a copy of the image's.
if [ -n "${STARSHIP_CONFIG:-}" ] && [ ! -r "$STARSHIP_CONFIG" ]; then
  unset STARSHIP_CONFIG
fi
if command -v starship >/dev/null 2>&1; then
  if [ -n "${ZSH_VERSION:-}" ]; then
    eval "$(starship init zsh)"
  elif [ -n "${BASH_VERSION:-}" ]; then
    eval "$(starship init bash)"
  fi
fi
