# Dev (mise, Claude Code, GitHub CLI) (dev)

A thin template on top of the prebuilt image `ghcr.io/andykenward/devcontainer-dev`, which includes:

- **mise**: manages Node.js (the current LTS major by default, with corepack for pnpm and yarn) and any other runtime. A project's `mise.toml`, `.tool-versions`, `.nvmrc` or `.node-version` is installed on create.
- **Claude Code CLI** (`claude`), installed fresh on every create (see [Claude Code versions](#claude-code-versions)), and the Claude Code VS Code extension
- **GitHub CLI** (`gh`)
- **zizmor**: audits GitHub Actions workflows for security problems (`zizmor .`)
- zsh with Oh My Zsh, git, and the usual base image tools

## Options

| Option | Description | Default |
| --- | --- | --- |
| `imageVariant` | Image tag. A major version (`1`) gets compatible releases and the weekly rebuilds, but no breaking changes. Also `1.2` or `1.2.3` to pin further, `latest`, or an exact build such as `1.2.3-2026-11-07` | `1` |
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

## mise security

- **Trust:** on create, mise trusts the project's own config (its `mise.toml`, `.tool-versions` and so on). Any other config, such as a repo you clone inside the project, gets no trust until you run `mise trust` there. Until then, its env, hooks and tasks don't run.
- **No community plugins:** paranoid mode refuses to install unregistered community plugins, and the `asdf` and `vfox` plugin backends are off. A project that needs them can set `disable_backends = []` in its own `mise.toml`.
- **Verification:** mise checks checksums, GitHub attestations, SLSA, cosign and npm provenance where tools publish them. For pinned versions, commit a `mise.lock` (see `lockfile` and `locked` in the mise docs).

## Updating

The image is rebuilt every week from the newest release of its current and previous major, and the version tags move to the new build. Use **Dev Containers: Rebuild Container** to pull it. Pin an exact build with its dated tag (`1.0.0-2026-11-07`) if a rebuild ever breaks something. A breaking image change gets a new major version: switch `1` to `2` in `devcontainer.json` when you are ready. See the [image changelog](https://github.com/andykenward/devcontainers-templates/blob/main/images/dev/CHANGELOG.md).

### Claude Code versions

The Claude Code CLI isn't baked into the image. Each create or rebuild installs the newest release, and the CLI's auto-updater keeps it current while the container runs. Run `claude update` to update right away.

To start a project on a specific version, set it in the project's `devcontainer.json`:

```jsonc
"containerEnv": {
  "CLAUDE_CODE_VERSION": "stable", // or an exact version such as "2.1.319"
  "DISABLE_AUTOUPDATER": "1"       // optional: stay on that version
}
```

The VS Code extension bundles its own copy of Claude Code and updates with the extension.
