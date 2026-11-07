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
