# Changelog

## [2.0.0](https://github.com/andykenward/devcontainers-templates/compare/template-v1.3.0...template-v2.0.0) (2026-11-08)


### ⚠ BREAKING CHANGES

* **template:** volumePrefix no longer covers mise installs; new projects no longer share runtimes and tools. Existing projects keep their copy of the template until they change the mount themselves.

### Features

* **template:** give each project its own mise volume ([#25](https://github.com/andykenward/devcontainers-templates/issues/25)) ([11ed3a1](https://github.com/andykenward/devcontainers-templates/commit/11ed3a1e80d96cefc323e69a654810669001050d))

## [1.3.0](https://github.com/andykenward/devcontainers-templates/compare/template-v1.2.1...template-v1.3.0) (2026-11-08)


### Features

* add the starship prompt with per-project config ([#22](https://github.com/andykenward/devcontainers-templates/issues/22)) ([b4d3a13](https://github.com/andykenward/devcontainers-templates/commit/b4d3a13d8f6f380904b1f2471a0d39eb0c45f9a0))

## [1.2.1](https://github.com/andykenward/devcontainers-templates/compare/template-v1.2.0...template-v1.2.1) (2026-11-07)


### Bug Fixes

* **image:** skip gh auth setup-git when an SSH agent has a key ([#21](https://github.com/andykenward/devcontainers-templates/issues/21)) ([38f1414](https://github.com/andykenward/devcontainers-templates/commit/38f14145f04f04f05140bfeaa68f9e7bd1e23f32))

## [1.2.0](https://github.com/andykenward/devcontainers-templates/compare/template-v1.1.0...template-v1.2.0) (2026-11-07)


### Features

* **image:** rebuild the previous major weekly, pin the Node major and tag exact builds &lt;X.Y.Z&gt;-&lt;date&gt; ([#12](https://github.com/andykenward/devcontainers-templates/issues/12)) ([3be9d75](https://github.com/andykenward/devcontainers-templates/commit/3be9d75645f0dbcfe78b87d141d7256a8cfc31dc))
* persist git config across container rebuilds ([#15](https://github.com/andykenward/devcontainers-templates/issues/15)) ([732279b](https://github.com/andykenward/devcontainers-templates/commit/732279b2e959f9953cab47755c7980ec9f0af6ff))

## [1.1.0](https://github.com/andykenward/devcontainers-templates/compare/template-v1.0.0...template-v1.1.0) (2026-11-07)


### Features

* **repo:** version releases with release-please and check PR titles ([#9](https://github.com/andykenward/devcontainers-templates/issues/9)) ([b09f851](https://github.com/andykenward/devcontainers-templates/commit/b09f85101e13266e4c263eed2dbda463b7f8bfc9))
