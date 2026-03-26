#!/usr/bin/env bats
# ================================================================
# Tests for bin/finalize
#
# These tests run finalize in isolation by providing a minimal
# BUILD_DIR with the expected structure. Bun must be available
# on PATH for the smoke test; we use bun if available or skip
# smoke-test-dependent checks.
# ================================================================

load test_helper/common_setup

setup() {
  setup_common
  # finalize needs bun on PATH — set up from supply phase location
  export PATH="${DEPS_DIR}/${DEPS_IDX}/bun/bin:${DEPS_DIR}/${DEPS_IDX}/bin:${PATH}"
}

teardown() {
  teardown_common
}

@test "finalize: fails when package.json is missing" {
  create_node_modules "$BUILD_DIR" hono
  mkdir -p "${BUILD_DIR}/node_modules/.bin"

  run "${BUILDPACK_DIR}/bin/finalize" "$BUILD_DIR" "$CACHE_DIR" "$DEPS_DIR" "$DEPS_IDX"
  [ "$status" -eq 1 ]
  [[ "$output" == *"package.json not found"* ]]
}

@test "finalize: passes with package.json + valid node_modules (pre-bundled mode)" {
  create_package_json "$BUILD_DIR"
  create_node_modules "$BUILD_DIR" hono
  mkdir -p "${BUILD_DIR}/node_modules/.bin"

  run "${BUILDPACK_DIR}/bin/finalize" "$BUILD_DIR" "$CACHE_DIR" "$DEPS_DIR" "$DEPS_IDX"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Validation passed"* ]]
  [[ "$output" == *"pre-bundled"* ]]
}

@test "finalize: passes with package.json + scripts.start + no node_modules (single-file bundle mode)" {
  create_package_json "$BUILD_DIR" '{"name":"test","version":"1.0.0","scripts":{"start":"bun run dist/app.js"}}'

  run "${BUILDPACK_DIR}/bin/finalize" "$BUILD_DIR" "$CACHE_DIR" "$DEPS_DIR" "$DEPS_IDX"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Validation passed"* ]]
  [[ "$output" == *"single-file bundle"* ]]
}

@test "finalize: warns with no scripts.start and no node_modules (single-file mode without start)" {
  create_package_json "$BUILD_DIR" '{"name":"test","version":"1.0.0"}'

  run "${BUILDPACK_DIR}/bin/finalize" "$BUILD_DIR" "$CACHE_DIR" "$DEPS_DIR" "$DEPS_IDX"
  [ "$status" -eq 0 ]
  [[ "$output" == *"single-file bundle"* ]]
  [[ "$output" == *"No scripts.start found"* ]]
  [[ "$output" == *"mta.yaml"* ]]
}

@test "finalize: fails with empty node_modules" {
  create_package_json "$BUILD_DIR"
  mkdir -p "${BUILD_DIR}/node_modules"

  run "${BUILDPACK_DIR}/bin/finalize" "$BUILD_DIR" "$CACHE_DIR" "$DEPS_DIR" "$DEPS_IDX"
  [ "$status" -eq 1 ]
  [[ "$output" == *"appears empty"* ]]
}

@test "finalize: warns on symlinks in node_modules" {
  create_package_json "$BUILD_DIR"
  create_node_modules "$BUILD_DIR" hono
  create_symlinked_modules "$BUILD_DIR" fake-link-a fake-link-b
  mkdir -p "${BUILD_DIR}/node_modules/.bin"

  run "${BUILDPACK_DIR}/bin/finalize" "$BUILD_DIR" "$CACHE_DIR" "$DEPS_DIR" "$DEPS_IDX"
  [ "$status" -eq 0 ]
  [[ "$output" == *"symlinks in node_modules"* ]]
}

@test "finalize: reports app name" {
  create_package_json "$BUILD_DIR" '{"name":"my-cool-app","version":"1.0.0","dependencies":{"hono":"^4.0.0"}}'
  create_node_modules "$BUILD_DIR" hono
  mkdir -p "${BUILD_DIR}/node_modules/.bin"

  run "${BUILDPACK_DIR}/bin/finalize" "$BUILD_DIR" "$CACHE_DIR" "$DEPS_DIR" "$DEPS_IDX"
  [ "$status" -eq 0 ]
  [[ "$output" == *"App name: my-cool-app"* ]]
}

@test "finalize: smoke test passes with unscoped dependency" {
  create_package_json "$BUILD_DIR" '{"name":"test","version":"1.0.0","scripts":{"start":"bun run server.js"},"dependencies":{"hono":"^4.0.0"}}'
  create_node_modules "$BUILD_DIR" hono
  mkdir -p "${BUILD_DIR}/node_modules/.bin"

  # Only run smoke test if bun is available
  if command -v bun >/dev/null 2>&1; then
    run "${BUILDPACK_DIR}/bin/finalize" "$BUILD_DIR" "$CACHE_DIR" "$DEPS_DIR" "$DEPS_IDX"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Dependency smoke test passed"* ]]
  else
    skip "bun not available for smoke test"
  fi
}

@test "finalize: smoke test passes with scoped dependency" {
  create_package_json "$BUILD_DIR" '{"name":"test","version":"1.0.0","scripts":{"start":"bun run server.js"},"dependencies":{"@scope/pkg":"^1.0.0"}}'
  # Create scoped package in node_modules
  mkdir -p "${BUILD_DIR}/node_modules/@scope/pkg"
  echo '{"name":"@scope/pkg","version":"1.0.0","main":"index.js"}' > "${BUILD_DIR}/node_modules/@scope/pkg/package.json"
  echo "module.exports = {};" > "${BUILD_DIR}/node_modules/@scope/pkg/index.js"
  mkdir -p "${BUILD_DIR}/node_modules/.bin"

  if command -v bun >/dev/null 2>&1; then
    run "${BUILDPACK_DIR}/bin/finalize" "$BUILD_DIR" "$CACHE_DIR" "$DEPS_DIR" "$DEPS_IDX"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Dependency smoke test passed"* ]]
  else
    skip "bun not available for smoke test"
  fi
}

@test "finalize: permission fix applied to node_modules" {
  create_package_json "$BUILD_DIR"
  create_node_modules "$BUILD_DIR" hono
  mkdir -p "${BUILD_DIR}/node_modules/.bin"
  # Create a fake bin script
  echo '#!/bin/bash' > "${BUILD_DIR}/node_modules/.bin/hono"

  run "${BUILDPACK_DIR}/bin/finalize" "$BUILD_DIR" "$CACHE_DIR" "$DEPS_DIR" "$DEPS_IDX"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Setting file permissions"* ]]

  # Verify .bin script is executable
  [ -x "${BUILD_DIR}/node_modules/.bin/hono" ]
}
