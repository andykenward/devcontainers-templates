# devcontainers-templates

## Commits and PR titles

PRs are squash-merged with the PR title as the commit message, and release-please reads those titles to version and describe releases. Use [Conventional Commits](https://www.conventionalcommits.org) for every PR title and commit message: `<type>(<optional scope>)<optional !>: <description>`. The PR title check (`.github/workflows/pr-title.yaml`) blocks merging otherwise.

- `feat`: new behaviour (minor release). `fix`, `perf`, `deps`, `revert`: patch release. Add `!` after the type/scope, or a `BREAKING CHANGE:` footer, for a breaking change (major release).
- `docs`, `chore`, `refactor`, `test`, `build`, `ci`, `style`: no release.
- A change only releases the component whose files it touches: `images/dev/` (image) or `src/dev/` (template). Use scopes `image`, `template`, `ci`, `deps` or `repo` to say which part changed.
- Write the description in the imperative and lowercase, as it reads in the changelog: `feat(image): add zizmor`.

Never edit versions or changelogs by hand (`.release-please-manifest.json`, `version` in `src/dev/devcontainer-template.json`, `images/dev/CHANGELOG.md`, `docs/changelogs/`). Merging the Release PR updates them.

## Checks

Run `mise run lint` (ShellCheck and zizmor) before pushing, and `mise run test` (image build and template test, needs Docker) when the image, template or test scripts change.
