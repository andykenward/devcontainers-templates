# Dev (mise, Claude Code, GitHub CLI) (dev)

A thin template on top of the prebuilt image `ghcr.io/andykenward/devcontainer-dev`, which includes:

- **mise**: manages Node.js (an LTS major pinned by the image, 26 in image `1`, with corepack for pnpm and yarn) and any other runtime. A project's `mise.toml`, `.tool-versions`, `.nvmrc` or `.node-version` is installed on create.
- **Claude Code CLI** (`claude`), installed fresh on every create (see [Claude Code versions](#claude-code-versions)), and the Claude Code VS Code extension
- **GitHub CLI** (`gh`)
- **zizmor**: audits GitHub Actions workflows for security problems (`zizmor .`)
- **Starship** prompt in bash and zsh (see [Prompt](#prompt))
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
| `<prefix>-git` | `~/.config/git` (git's own config file, `~/.config/git/config`) | shared |
| `<prefix>-mise` | `~/.local/share/mise` (installed runtimes) | shared |
| `<devcontainerId>-history` | `/commandhistory` (bash and zsh history) | per project |
| `<devcontainerId>-vscode-extensions` | `~/.vscode-server/extensions` | per project |

Log in once (`claude`, `gh auth login`) and every container that uses the same prefix stays logged in.

Git settings work the same way. Write them to `~/.config/git/config` instead of `~/.gitconfig`, which the container recreates on every rebuild. For example, to sign commits with an SSH key from a forwarded agent (such as 1Password's):

```sh
git config --file ~/.config/git/config user.name "Your Name"
git config --file ~/.config/git/config user.email "you@example.com"
git config --file ~/.config/git/config gpg.format ssh
git config --file ~/.config/git/config user.signingkey "key::$(ssh-add -L | head -1)"
git config --file ~/.config/git/config commit.gpgsign true
```

`~/.gitconfig` is read after `~/.config/git/config`, so anything VS Code copies there from your host's `~/.gitconfig` wins. In particular, a host `gpg.ssh.program` that points at a macOS app breaks signing in the container. Remove it from the host config or override it in `~/.gitconfig`.

To start over, delete a volume, for example `docker volume rm devcontainer-claude`.

## Prompt

bash and zsh both use the [Starship](https://starship.rs) prompt, configured by the image's `~/.config/starship.toml`. That config updates with image releases. On top of Starship's defaults (git branch and status, runtime versions, command duration), it shows the exit code of a failed command, mise's health and the lines changed in git. It uses symbols that every font has, so no Nerd Font is needed.

To change the prompt for a project, copy the image's config into the project and edit the copy:

```sh
cp ~/.config/starship.toml .devcontainer/starship.toml
```

The template sets `STARSHIP_CONFIG` to `.devcontainer/starship.toml`, and that file is used once it exists. Open a new terminal to see changes; no rebuild needed. Starship reads only one config, so the project file replaces the image's instead of adding to it, and it no longer gets the image's updates. Delete it to go back to the image's config.

If your host terminal has a Nerd Font, `starship preset nerd-font-symbols` in the project file gives you the icon set.

## mise security

- **Trust:** on create, mise trusts the project's own config (its `mise.toml`, `.tool-versions` and so on). Any other config, such as a repo you clone inside the project, gets no trust until you run `mise trust` there. Until then, its env, hooks and tasks don't run.
- **No community plugins:** paranoid mode refuses to install unregistered community plugins, and the `asdf` and `vfox` plugin backends are off. A project that needs them can set `disable_backends = []` in its own `mise.toml`.
- **Verification:** mise checks checksums, GitHub attestations, SLSA, cosign and npm provenance where tools publish them. For pinned versions, commit a `mise.lock` (see `lockfile` and `locked` in the mise docs).

## Updating

The image is rebuilt every week from the newest release of its current and previous major, and the version tags move to the new build. Use **Dev Containers: Rebuild Container** to pull it. Pin an exact build with its dated tag (`1.2.3-2026-11-07`) if a rebuild ever breaks something; a rebuild of the same release on the same day replaces that tag. A breaking image change gets a new major version: switch `1` to `2` in `devcontainer.json` when you are ready. See the [image changelog](https://github.com/andykenward/devcontainers-templates/blob/main/images/dev/CHANGELOG.md).

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
