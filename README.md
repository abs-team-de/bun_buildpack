# bun_buildpack

A custom Cloud Foundry buildpack for SAP BTP that deploys Bun applications with pre-bundled dependencies. It provides the Bun runtime and validates the application structure — but deliberately skips `bun install` at staging time.

Designed for teams whose internal packages live on registries (e.g., Azure Artifacts) that are not accessible from the CF staging environment. All dependencies are resolved and bundled locally (or in CI). The Bun runtime is downloaded during staging (and cached), but no `bun install` is ever executed.

## Features

- **Zero install at staging** — no `bun install`, no `npm install`; the Bun runtime is downloaded (and cached) but no dependency resolution occurs
- **Two deployment modes**:
  - **Pre-bundled**: `bun install --production` locally, package `node_modules/` into MTAR
  - **Single-file bundle**: `bun build` locally, package compiled output into MTAR
- **Bun version resolution** — reads `engines.bun` from `package.json`; supports exact versions only (`1.2.9`) and prefix operators (`^1.2.9`, `~1.2.9`, `>=1.2.9` — strip prefix, use base version)
- **SHA256 checksum verification** — fail-closed integrity check with 3 checksum sources (`BUN_DOWNLOAD_SHA256`, `BUN_SHASUMS_URL`, GitHub default)
- **Mirror support** — fully decouple from GitHub using `BUN_DOWNLOAD_URL` + `BUN_SHASUMS_URL`
- **Symlink detection** — warns if symlinks found in `node_modules/`
- **Dependency smoke test** — verifies at least one dependency resolves before the app starts (pre-bundled mode)
- **Staging cache** — Bun downloads are cached between deployments

## Usage

Reference this buildpack by its GitHub URL in your `mta.yaml`:

### Pre-bundled mode

```yaml
modules:
  - name: srv
    type: nodejs
    path: deploy/srv
    build-parameters:
      builder: custom
      commands: []
    parameters:
      buildpacks:
        - https://github.com/abs-team-de/bun_buildpack.git#v1.0.0
      memory: 512M
      disk_quota: 1024M
```

Before building the MTAR, install production dependencies:

```bash
bun install --production
```

The MTAR module should contain:
- `package.json` (with `engines.bun` and optionally `scripts.start`)
- `node_modules/` (flat, no symlinks)
- Built application files (e.g., `dist/`, `server.js`)

Not required at runtime: `bun.lockb`/`bun.lock` (harmless if included), `node_modules/.cache`

### Single-file bundle mode

```yaml
modules:
  - name: srv
    type: nodejs
    path: deploy/srv
    build-parameters:
      builder: custom
      commands: []
    parameters:
      buildpacks:
        - https://github.com/abs-team-de/bun_buildpack.git#v1.0.0
      memory: 256M
      disk_quota: 512M
      command: bun run dist/app.js
```

Before building the MTAR, compile your application:

```bash
bun build src/index.ts --outdir dist --target bun
```

The MTAR module should contain:
- `package.json` (with `scripts.start` or use `command` in mta.yaml)
- Compiled output (e.g., `dist/app.js`)

Not required: `node_modules/`, source files, lockfiles

## Configuration

| Source | Field / Variable | Example | Purpose |
|--------|-----------------|---------|---------|
| `package.json` | `engines.bun` | `"1.2.9"` | Bun version to install (exact only) |
| Environment | `BUN_OVERRIDE_VERSION` | `1.2.9` | Override Bun version (highest priority) |
| Environment | `BUN_DOWNLOAD_URL` | `https://internal.example.com/bun.zip` | Custom Bun download URL (mirror) |
| Environment | `BUN_SHASUMS_URL` | `https://internal.example.com/SHASUMS256.txt` | Custom checksums URL |
| Environment | `BUN_DOWNLOAD_SHA256` | `a1b2c3...` | Direct SHA256 hex string |
| Environment | `BUN_SKIP_CHECKSUM` | `true` | Skip checksum verification (not recommended) |

### Version resolution

Only exact three-part versions are supported: `1.2.9`, `^1.2.9`, `~1.2.9`, `>=1.2.9`.

**Not supported**: major only (`1`), major.minor (`1.2`), wildcards (`1.x`), ranges (`>=1 <2`), star (`*`). Bun's fast release cadence makes fuzzy resolution unreliable without an embedded version catalog. Pin an exact version.

### Mirror support

To fully decouple from GitHub (e.g., air-gapped environments):

```
BUN_DOWNLOAD_URL=https://internal.example.com/bun/bun-v1.2.9-linux-x64.zip
BUN_SHASUMS_URL=https://internal.example.com/bun/SHASUMS256.txt
```

The download URL must point to a zip containing `bun-linux-x64/bun`.

## Staging Output

```
-----> [bun] Supply phase starting
       Bun version: v1.2.9 (requested: '1.2.9')
-----> [bun] Downloading Bun v1.2.9
       SHA256 checksum verified
-----> [bun] Supply phase complete
       bun v1.2.9
-----> [bun] Finalize phase starting
-----> [bun] Validating pre-bundled application structure...
       App name: @myorg/srv
       Mode: pre-bundled (node_modules present)
       node_modules: 42 top-level packages
       Start script: bun run server.js
       Dependency smoke test passed (resolved 'hono')
-----> [bun] Validation passed — application is ready
-----> [bun] No bun install executed. Pre-bundled dependencies will be used as-is.
```

## Repository Structure

```
bun_buildpack/
├── bin/
│   ├── detect              # Matches apps with Bun markers
│   ├── supply              # Downloads and caches Bun runtime
│   ├── finalize            # Validates the pre-bundled structure
│   └── release             # Provides default start command
├── lib/
│   └── utils.sh            # Shared helpers: logging, version resolution
├── test/
│   ├── test_helper/
│   │   └── common_setup.bash
│   ├── detect.bats
│   ├── supply.bats
│   ├── finalize.bats
│   ├── release.bats
│   └── utils.bats
├── LICENSE
└── README.md
```

## Why Not the Standard nodejs_buildpack?

The Cloud Foundry `nodejs_buildpack` always runs `npm install` or `npm rebuild` during staging. This behavior is compiled into the Go binary and cannot be disabled via configuration. There is no Bun support. On SAP BTP, `cf create-buildpack` is not available to customers, so uploading a modified version is not an option.

This buildpack solves both problems: it's referenced by GitHub URL (no upload needed) and it never runs any package manager install step.

## Compatibility

- **CF Stack**: cflinuxfs4 (Ubuntu 22.04, glibc 2.35)
- **Bun**: Any linux-x64 release from github.com/oven-sh/bun (default: 1.2.9)
- **Architecture**: x86_64 (linux-x64)
- **SAP BTP**: Tested on SAP BTP Cloud Foundry multi-environment subaccounts

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Security

See [SECURITY.md](SECURITY.md) for vulnerability reporting.

## License

[Apache-2.0](LICENSE)
