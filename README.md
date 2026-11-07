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

## Workflows

- **Build image** (`build-image.yaml`): runs on pushes to `images/**`, every Monday and on demand. It pushes `latest` and `yyyy-mm-dd` tags for amd64 and arm64.
- **Test** (`test.yaml`): runs on PRs. It builds the image locally, applies the template, runs `test/dev/test.sh`, rebuilds the container and checks that the volumes persisted.
- **Release templates** (`release-templates.yaml`): runs on pushes to `src/**`. It publishes the templates to GHCR. Bump `version` in `devcontainer-template.json` to release.
- **Dependabot** (`.github/dependabot.yml`): keeps the base image, devcontainer features and actions up to date each week.

After the first publish, set both GHCR packages to **public** under the package settings on GitHub. Otherwise they need `docker login` to pull.

## Local development

Open this repo in its dev container, then:

```bash
mise run lint   # shellcheck + zizmor
mise run test   # build the image and test the template
```
