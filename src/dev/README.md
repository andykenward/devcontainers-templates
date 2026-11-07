# Dev (mise, Claude Code, GitHub CLI) (dev)

A thin template on top of the prebuilt image `ghcr.io/andykenward/devcontainer-dev`, which includes:

- **mise**: manages Node.js (LTS by default, with corepack for pnpm and yarn) and any other runtime. A project's `mise.toml`, `.tool-versions`, `.nvmrc` or `.node-version` is installed on create.
- **Claude Code CLI** (`claude`) and the Claude Code VS Code extension
- **GitHub CLI** (`gh`)
- zsh with Oh My Zsh, git, and the usual base image tools

## Options

| Option | Description | Default |
| --- | --- | --- |
| `imageVariant` | Image tag: `latest`, or a dated tag such as `2026-11-07` to pin | `latest` |
| `volumePrefix` | Prefix for the shared volumes. Projects with the same prefix share logins and tool installs | `devcontainer` |

## What persists across rebuilds

| Volume | Mounted at | Scope |
| --- | --- | --- |
| `<prefix>-claude` | `~/.claude` (`CLAUDE_CONFIG_DIR`, which includes `.claude.json`) | shared |
| `<prefix>-gh` | `~/.config/gh` | shared |
| `<prefix>-mise` | `~/.local/share/mise` (installed runtimes) | shared |
| `<devcontainerId>-history` | `/commandhistory` (bash and zsh history) | per project |
| `<devcontainerId>-vscode-extensions` | `~/.vscode-server/extensions` | per project |

Log in once (`claude`, `gh auth login`) and every container that uses the same prefix stays logged in.

To start over, delete a volume, for example `docker volume rm devcontainer-claude`.

## Updating

The image is rebuilt every week. Use **Dev Containers: Rebuild Container** to pull the newest `latest`.
