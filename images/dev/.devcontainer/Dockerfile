# Prebuilt dev image: mise (Node.js + any other runtimes), GitHub CLI, zizmor.
# The Claude Code CLI is installed at create time by devcontainer-post-create.
# Built and published by .github/workflows/build-image.yaml.
# Base image is pinned to an exact version so Dependabot can bump it.
FROM mcr.microsoft.com/devcontainers/base:3.0.12-ubuntu24.04

ARG USERNAME=vscode
ARG NODE_VERSION=lts

# --- mise (system install from the official apt repo) -----------------------
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates curl gpg; \
    install -dm 755 /etc/apt/keyrings; \
    curl -fsSL https://mise.jdx.dev/gpg-key.pub | gpg --dearmor -o /etc/apt/keyrings/mise-archive-keyring.gpg; \
    echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg arch=$(dpkg --print-architecture)] https://mise.jdx.dev/deb stable main" \
      > /etc/apt/sources.list.d/mise.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends mise; \
    apt-get clean; rm -rf /var/lib/apt/lists/*

# --- Environment ---------------------------------------------------------------
# CLAUDE_CONFIG_DIR moves ~/.claude.json into ~/.claude so a single volume
# persists Claude Code's login, settings and history across rebuilds.
ENV CLAUDE_CONFIG_DIR=/home/${USERNAME}/.claude \
    MISE_DATA_DIR=/home/${USERNAME}/.local/share/mise \
    MISE_TRUSTED_CONFIG_PATHS=/workspaces \
    MISE_NODE_COREPACK=true \
    PATH=/home/${USERNAME}/.local/bin:/home/${USERNAME}/.local/share/mise/shims:${PATH}

# Every directory that the template mounts a volume onto must exist in the image
# and be owned by the user. Docker copies image content (and ownership) into an
# empty named volume on first use; a missing directory would be created as root.
RUN set -eux; \
    mkdir -p /commandhistory; \
    chown ${USERNAME}:${USERNAME} /commandhistory; \
    su ${USERNAME} -c "mkdir -p \
      /home/${USERNAME}/.claude \
      /home/${USERNAME}/.config/gh \
      /home/${USERNAME}/.config/mise \
      /home/${USERNAME}/.local/bin \
      /home/${USERNAME}/.local/share/mise \
      /home/${USERNAME}/.vscode-server/extensions"

COPY --chmod=755 devcontainer-post-create.sh /usr/local/bin/devcontainer-post-create
COPY --chown=${USERNAME}:${USERNAME} shellrc.sh /home/${USERNAME}/.devcontainer-shellrc.sh

USER ${USERNAME}

# Shell integration: mise activation + persistent history for bash and zsh.
RUN set -eux; \
    echo '. "$HOME/.devcontainer-shellrc.sh"' >> ~/.bashrc; \
    echo '. "$HOME/.devcontainer-shellrc.sh"' >> ~/.zshrc

# Global tools via mise (projects override with their own mise.toml/.nvmrc/.node-version):
# Node.js, and zizmor for auditing GitHub Actions workflows. They live in
# ~/.config/mise/config.toml, so postCreate's `mise install` also puts them on
# the shared mise volume.
RUN set -eux; \
    mise settings set idiomatic_version_file_enable_tools node; \
    mise use --global "node@${NODE_VERSION}" zizmor@latest; \
    mise reshim; \
    node --version; npm --version; zizmor --version

# The Claude Code CLI is not in the image: devcontainer-post-create installs the
# newest release into ~/.local/bin on every create, so projects never start on a
# stale version.

USER root
