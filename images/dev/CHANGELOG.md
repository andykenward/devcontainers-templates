# Changelog

## [1.3.0](https://github.com/andykenward/devcontainers-templates/compare/image-v1.2.0...image-v1.3.0) (2026-11-08)


### Features

* **image:** run an init process and add the mise extension ([#29](https://github.com/andykenward/devcontainers-templates/issues/29)) ([fc75fd0](https://github.com/andykenward/devcontainers-templates/commit/fc75fd0cbc58f1c349abbfee456dea832bac451b))


### Bug Fixes

* **image:** keep gh's credential helper off the shared volume and test builds before tagging ([#33](https://github.com/andykenward/devcontainers-templates/issues/33)) ([aa43507](https://github.com/andykenward/devcontainers-templates/commit/aa4350797c71c4abf8e50b6517ce7824f4a596cf))
* **image:** keep post-create going when mise install fails ([#28](https://github.com/andykenward/devcontainers-templates/issues/28)) ([fe59ae2](https://github.com/andykenward/devcontainers-templates/commit/fe59ae224a616d93637ec328e5dd5dfe4ed35a4e))
* **image:** start starship when a stale mise shim shadows it ([#24](https://github.com/andykenward/devcontainers-templates/issues/24)) ([c9fd025](https://github.com/andykenward/devcontainers-templates/commit/c9fd0251c1381a3a4e3fba32858df94e38f90207))
* **image:** use the project's tool versions outside terminals ([#27](https://github.com/andykenward/devcontainers-templates/issues/27)) ([360dcf0](https://github.com/andykenward/devcontainers-templates/commit/360dcf005884fadf2912c268b7ff0d48301506f2))

## [1.2.0](https://github.com/andykenward/devcontainers-templates/compare/image-v1.1.1...image-v1.2.0) (2026-11-08)


### Features

* add the starship prompt with per-project config ([#22](https://github.com/andykenward/devcontainers-templates/issues/22)) ([b4d3a13](https://github.com/andykenward/devcontainers-templates/commit/b4d3a13d8f6f380904b1f2471a0d39eb0c45f9a0))

## [1.1.1](https://github.com/andykenward/devcontainers-templates/compare/image-v1.1.0...image-v1.1.1) (2026-11-07)


### Bug Fixes

* **image:** skip gh auth setup-git when an SSH agent has a key ([#21](https://github.com/andykenward/devcontainers-templates/issues/21)) ([38f1414](https://github.com/andykenward/devcontainers-templates/commit/38f14145f04f04f05140bfeaa68f9e7bd1e23f32))

## [1.1.0](https://github.com/andykenward/devcontainers-templates/compare/image-v1.0.0...image-v1.1.0) (2026-11-07)


### Features

* **image:** rebuild the previous major weekly, pin the Node major and tag exact builds &lt;X.Y.Z&gt;-&lt;date&gt; ([#12](https://github.com/andykenward/devcontainers-templates/issues/12)) ([3be9d75](https://github.com/andykenward/devcontainers-templates/commit/3be9d75645f0dbcfe78b87d141d7256a8cfc31dc))
* persist git config across container rebuilds ([#15](https://github.com/andykenward/devcontainers-templates/issues/15)) ([732279b](https://github.com/andykenward/devcontainers-templates/commit/732279b2e959f9953cab47755c7980ec9f0af6ff))

## 1.0.0 (2026-11-07)


### Features

* **repo:** version releases with release-please and check PR titles ([#9](https://github.com/andykenward/devcontainers-templates/issues/9)) ([b09f851](https://github.com/andykenward/devcontainers-templates/commit/b09f85101e13266e4c263eed2dbda463b7f8bfc9))
