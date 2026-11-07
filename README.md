# devcontainers-templates

My personal [dev container](https://containers.dev) setup: a **prebuilt image** and a **thin template** that uses it.

| Path | What |
| --- | --- |
| `images/dev/` | The prebuilt image (mise + Node LTS, GitHub CLI, zizmor; Claude Code is installed on create), published as `ghcr.io/andykenward/devcontainer-dev` |
| `src/dev/` | The `dev` template, published as `ghcr.io/andykenward/devcontainers-templates/dev`. See [its README](src/dev/README.md) |
| `test/dev/` | Checks that run inside a container created from the template |
| `.devcontainer/` | Dev container for working on this repo (builds the image locally and adds Docker-in-Docker) |

## Use the template

In VS Code, run **Dev Containers: Add Dev Container Configuration Files…**, choose **Show All Definitions…** and enter `ghcr.io/andykenward/devcontainers-templates/dev`.

With the CLI:

```bash
devcontainer templates apply -t ghcr.io/andykenward/devcontainers-templates/dev
```

## Releases and versions

The image and the template are versioned separately with [semver](https://semver.org), by [release-please](https://github.com/googleapis/release-please):

| Component | Git tag | Changelog | Published as |
| --- | --- | --- | --- |
| Image (`images/dev/`) | `image-v<X.Y.Z>` | [`images/dev/CHANGELOG.md`](images/dev/CHANGELOG.md) | `ghcr.io/andykenward/devcontainer-dev:<X.Y.Z>`, `:<X.Y>`, `:<X>`, `:latest`, `:<yyyy-mm-dd>` |
| Template (`src/dev/`) | `template-v<X.Y.Z>` | [`docs/changelogs/template-dev.md`](docs/changelogs/template-dev.md) | `ghcr.io/andykenward/devcontainers-templates/dev:<X.Y.Z>` (and `X.Y`, `X`, `latest`) |

How a change gets released:

1. **PR titles follow [Conventional Commits](https://www.conventionalcommits.org)** (`feat(image): add zizmor`). PRs are squash-merged, so the title becomes the commit on `main`. `feat` makes a minor release, `fix`, `perf` and `deps` a patch release, and `!` (`feat!:`) a major one. `docs`, `chore`, `ci` and the like don't release. See [CLAUDE.md](CLAUDE.md) for the full list.
2. **release-please keeps a Release PR open** with the next versions and changelog entries.
3. **Merging the Release PR releases:** it tags the version(s), creates GitHub Releases, builds and pushes the image, then publishes the template.

The image is also rebuilt weekly from its latest release, so its version tags pick up the newest base image packages, mise, Node LTS, gh and zizmor without a new release. The template's `imageVariant` defaults to the image's major version (`1`), so projects get those updates and compatible releases, but not breaking ones. A breaking image change bumps that default in the same PR; the template publish checks it matches the newest image release.

## Workflows

- **PR title** (`pr-title.yaml`): checks that PR titles are Conventional Commits.
- **Test** (`test.yaml`): runs on PRs and pushes to `main`. Lints with ShellCheck and zizmor, builds the image locally, applies the template, runs `test/dev/test.sh`, rebuilds the container and checks that the volumes persisted.
- **Release** (`release.yaml`): runs release-please on pushes to `main`. When a release is created, it calls Build image and then Release templates.
- **Build image** (`build-image.yaml`): builds an image release for amd64 and arm64 and pushes its tags. It runs on release, every Monday (rebuilding the latest release) and on demand.
- **Release templates** (`release-templates.yaml`): publishes the templates to GHCR. It runs on release and on demand.
- **Dependabot** (`.github/dependabot.yml`): keeps the base image, devcontainer features and actions up to date each week.
- **Upgrade tools** (`upgrade-tools.yaml`): runs daily. It bumps the repo's mise tools in `mise.lock` (Dependabot can't read mise files), runs lint and the template test with them, and opens or updates a `mise-upgrade` PR when they pass.
  New releases wait out a 7-day cooldown (`minimum_release_age` in `mise.toml`). For an urgent security fix, lock the exact version yourself with `mise lock <tool>@<version>` (exact versions skip the cooldown) and open a PR.

After the first publish, set both GHCR packages to **public** under the package settings on GitHub. Otherwise they need `docker login` to pull.

### Repository settings

- **General → Pull Requests:** allow only **squash merging**, with **Pull request title** as the default commit message.
- **Rules → Rulesets** for `main`: require a pull request, and require the **PR title** and **Test** status checks.
- **Optional GitHub App** for the bots: PRs opened with `GITHUB_TOKEN` (the Release PR and the `mise-upgrade` PR) don't trigger other workflows, so required checks never run on them. Create a GitHub App with *Contents* and *Pull requests* read and write, install it on this repo, and add its client ID as the variable `BOT_APP_CLIENT_ID` and a private key as the secret `BOT_APP_PRIVATE_KEY`. Both workflows then use the App's token. Without it, merge those PRs with a ruleset bypass.

## Local development

Open this repo in its dev container, then:

```bash
mise run lint   # shellcheck + zizmor
mise run test   # build the image and test the template
```
