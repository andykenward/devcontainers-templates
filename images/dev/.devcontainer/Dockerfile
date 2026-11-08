# Prebuilt dev image: mise (Node.js + any other runtimes), GitHub CLI, zizmor,
# Starship prompt.
# The Claude Code CLI is installed at create time by devcontainer-post-create.
# Built and published by .github/workflows/build-image.yaml.
# Base image is pinned to an exact version so Dependabot can bump it.
FROM mcr.microsoft.com/devcontainers/base:3.0.12-ubuntu24.04

ARG USERNAME=vscode
# Node major. Pinned so a weekly rebuild can't move projects to a new LTS line
# under the same image tag. Bump it in a feat(image)!: PR when the next LTS lands
# (even-numbered majors, each October); the rebuild still picks up 26.x patches.
ARG NODE_VERSION=26

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
      /home/${USERNAME}/.config/git \
      /home/${USERNAME}/.config/mise \
      /home/${USERNAME}/.local/bin \
      /home/${USERNAME}/.local/share/mise \
      /home/${USERNAME}/.vscode-server/extensions"

COPY --chmod=755 devcontainer-post-create.sh /usr/local/bin/devcontainer-post-create
COPY --chown=${USERNAME}:${USERNAME} shellrc.sh /home/${USERNAME}/.devcontainer-shellrc.sh
COPY --chown=${USERNAME}:${USERNAME} starship.toml /home/${USERNAME}/.config/starship.toml

USER ${USERNAME}

# Shell integration for bash and zsh: mise activation, persistent history and
# the Starship prompt.
RUN set -eux; \
    echo '. "$HOME/.devcontainer-shellrc.sh"' >> ~/.bashrc; \
    echo '. "$HOME/.devcontainer-shellrc.sh"' >> ~/.zshrc

# Global tools via mise (projects override with their own mise.toml/.nvmrc/.node-version):
# Node.js, and zizmor for auditing GitHub Actions workflows. They live in
# ~/.config/mise/config.toml, so postCreate's `mise install` also puts them on
# the shared mise volume.
#
# Hardening, in the same global config:
# - paranoid "plugins": refuse to install unregistered community plugins.
# - disable_backends: the asdf and vfox plugin backends run community install
#   scripts. A trusted project that needs them can set disable_backends = []
#   in its own mise.toml.
# No config path is trusted automatically: postCreate trusts the project's own
# config, and anything else (e.g. a repo cloned to look at) asks first.
RUN set -eux; \
    mise settings set paranoid plugins; \
    mise settings set disable_backends asdf,vfox; \
    mise settings set idiomatic_version_file_enable_tools node; \
    mise use --global "node@${NODE_VERSION}" zizmor@latest; \
    mise reshim; \
    node --version; npm --version; zizmor --version

# Starship prompt (configured in ~/.config/starship.toml), in /usr/local/bin
# rather than the mise data dir. That dir is the shared mise volume, and an
# existing volume keeps its old content, so the prompt would only appear once
# postCreate's `mise install` had run. mise still downloads and verifies it,
# then forgets it so it isn't left in the image's copy of the volume.
RUN set -eux; \
    mise install starship@latest; \
    sudo install -m 755 "$(mise where starship@latest)/starship" /usr/local/bin/starship; \
    mise uninstall starship@latest; \
    starship --version

# The Claude Code CLI is not in the image: devcontainer-post-create installs the
# newest release into ~/.local/bin on every create, so projects never start on a
# stale version.

USER root

# Labels last: IMAGE_VERSION changes every release, and anything that uses a
# changed ARG (and every RUN after it) misses the layer cache. Here it only
# touches this metadata layer, so the cached installs above are reused.
# IMAGE_VERSION is passed by build-image.yaml; "dev" for local and test builds.
ARG IMAGE_VERSION=dev
LABEL org.opencontainers.image.title="devcontainer-dev" \
      org.opencontainers.image.description="Dev container image: mise, GitHub CLI, zizmor, Starship; Claude Code installed on create" \
      org.opencontainers.image.source="https://github.com/andykenward/devcontainers-templates" \
      org.opencontainers.image.version="${IMAGE_VERSION}"
