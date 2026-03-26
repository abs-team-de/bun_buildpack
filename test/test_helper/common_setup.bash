#!/usr/bin/env bash
# ================================================================
# Shared setup and helpers for Bats tests
# ================================================================

# Resolve paths relative to the repo root
BUILDPACK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

setup_common() {
  TEST_TEMP="$(mktemp -d)"
  BUILD_DIR="${TEST_TEMP}/build"
  CACHE_DIR="${TEST_TEMP}/cache"
  DEPS_DIR="${TEST_TEMP}/deps"
  DEPS_IDX="0"
  mkdir -p "$BUILD_DIR" "$CACHE_DIR" "${DEPS_DIR}/${DEPS_IDX}"

  # Source shared utilities
  source "${BUILDPACK_DIR}/lib/utils.sh"
}

teardown_common() {
  rm -rf "$TEST_TEMP"
}

# ── Helpers ──────────────────────────────────────────────────────

create_package_json() {
  local dir="$1"
  shift
  # Accept raw JSON content as the second argument
  if [ $# -gt 0 ]; then
    echo "$1" > "${dir}/package.json"
  else
    cat > "${dir}/package.json" <<'JSON'
{
  "name": "test-app",
  "version": "1.0.0",
  "engines": { "bun": "1.2.9" },
  "scripts": { "start": "bun run server.js" },
  "dependencies": { "hono": "^4.0.0" }
}
JSON
  fi
}

create_bun_lockb() {
  local dir="$1"
  # Touch a fake binary lockfile (Bun < 1.2)
  touch "${dir}/bun.lockb"
}

create_bun_lock() {
  local dir="$1"
  # Create a minimal text lockfile (Bun >= 1.2)
  cat > "${dir}/bun.lock" <<'LOCK'
{
  "lockfileVersion": 0,
  "packages": {}
}
LOCK
}

create_bunfig_toml() {
  local dir="$1"
  cat > "${dir}/bunfig.toml" <<'TOML'
[install]
production = true
TOML
}

create_node_modules() {
  local dir="$1"
  shift
  mkdir -p "${dir}/node_modules"
  # Create fake packages passed as arguments
  for pkg in "$@"; do
    mkdir -p "${dir}/node_modules/${pkg}"
    echo '{"name":"'"${pkg}"'","version":"1.0.0","main":"index.js"}' > "${dir}/node_modules/${pkg}/package.json"
    echo "module.exports = {};" > "${dir}/node_modules/${pkg}/index.js"
  done
}

create_symlinked_modules() {
  local dir="$1"
  shift
  mkdir -p "${dir}/node_modules"
  # Create a real package, then symlink others to it
  local real_pkg="_real_target"
  mkdir -p "${dir}/node_modules/${real_pkg}"
  echo '{"name":"'"${real_pkg}"'","version":"1.0.0"}' > "${dir}/node_modules/${real_pkg}/package.json"

  for pkg in "$@"; do
    ln -s "${dir}/node_modules/${real_pkg}" "${dir}/node_modules/${pkg}"
  done
}

# Create a minimal zip fixture that mimics the Bun release zip structure
create_bun_zip_fixture() {
  local target_zip="$1"
  local tmp_dir
  tmp_dir=$(mktemp -d)
  mkdir -p "${tmp_dir}/bun-linux-x64"
  # Create a fake bun binary (just a shell script)
  cat > "${tmp_dir}/bun-linux-x64/bun" <<'BUN'
#!/usr/bin/env bash
echo "1.2.9"
BUN
  chmod +x "${tmp_dir}/bun-linux-x64/bun"
  (cd "$tmp_dir" && zip -q -r "$target_zip" bun-linux-x64/)
  rm -rf "$tmp_dir"
}
