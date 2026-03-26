# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [1.0.0] — 2026-03-26

### Added

- `bin/detect` — matches apps with Bun markers (`bun.lockb`, `bun.lock`, `bunfig.toml`, `engines.bun`)
- `bin/supply` — downloads and caches Bun runtime with SHA256 checksum verification
- `bin/finalize` — validates pre-bundled application structure (two modes: pre-bundled and single-file bundle)
- `bin/release` — provides default start command from `package.json` with mode-aware fallbacks
- `lib/utils.sh` — shared logging, `read_package_field`, strict semver version resolution (exact versions only)
- SHA256 checksum verification with 3 sources: `BUN_DOWNLOAD_SHA256`, `BUN_SHASUMS_URL`, GitHub default
- Mirror support via `BUN_DOWNLOAD_URL` + `BUN_SHASUMS_URL` for air-gapped environments
- `BUN_SKIP_CHECKSUM=true` explicit bypass with warning
- `NODE_ENV=production` default via `profile.d`
- Staging cache for Bun downloads
- Dependency smoke test using `bun -e require.resolve(...)` (handles scoped packages)
- Bats test suite with tests covering detect, supply, finalize, release, and utils
- GitHub Actions CI workflow
- Apache-2.0 license
- SECURITY.md, CONTRIBUTING.md, issue/PR templates
