# devcontainers-templates

## Commits and PR titles

PRs are squash-merged with the PR title as the commit message, and release-please reads those titles to version and describe releases. Use [Conventional Commits](https://www.conventionalcommits.org) for every PR title and commit message: `<type>(<optional scope>)<optional !>: <description>`. The PR title check (`.github/workflows/pr-title.yaml`) blocks merging otherwise.

- `feat`: new behaviour (minor release). `fix`, `perf`, `deps`, `revert`: patch release. Add `!` after the type/scope, or a `BREAKING CHANGE:` footer, for a breaking change (major release).
- `docs`, `chore`, `refactor`, `test`, `build`, `ci`, `style`: no release.
- A change only releases the component whose files it touches: `images/dev/` (image) or `src/dev/` (template). Use scopes `image`, `template`, `ci`, `deps` or `repo` to say which part changed.
- Write the description in the imperative and lowercase, as it reads in the changelog: `feat(image): add zizmor`.
- A breaking image change (`feat(image)!:`) must also move the template's `imageVariant` default and proposals in `src/dev/devcontainer-template.json` to the new major, in the same PR. Release templates refuses to publish a template whose default is not the newest image major.

Never edit versions or changelogs by hand (`.release-please-manifest.json`, `version` in `src/dev/devcontainer-template.json`, `images/dev/CHANGELOG.md`, `docs/changelogs/`). Merging the Release PR updates them.

## Checks

Run `mise run lint` (ShellCheck and zizmor) before pushing, and `mise run test` (image build and template test, needs Docker) when the image, template or test scripts change.

## Image

- The weekly **Build image** run rebuilds the newest release of the current and previous major without the layer cache. That is how the base image's packages, mise, gh, zizmor and Node patch releases update: they are unpinned in the Dockerfile on purpose, since Dependabot can't bump them. Don't pin them, and don't let the scheduled build use the cache.
- The Node major is pinned (`ARG NODE_VERSION` in the Dockerfile) so a rebuild can't move projects to a new LTS line under the same tag. Move it to the next LTS in a `feat(image)!:` PR.
- A version tag is a release as last built, not fixed bytes; `<X.Y.Z>-<yyyy-mm-dd>` is the exact build.
