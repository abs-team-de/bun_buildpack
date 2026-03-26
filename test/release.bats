#!/usr/bin/env bats
# ================================================================
# Tests for bin/release
# ================================================================

load test_helper/common_setup

setup() {
  setup_common
}

teardown() {
  teardown_common
}

# ── Pre-bundled mode (node_modules exists) ───────────────────────

@test "release: uses scripts.start when present (pre-bundled mode)" {
  create_package_json "$BUILD_DIR"
  create_node_modules "$BUILD_DIR" hono

  run "${BUILDPACK_DIR}/bin/release" "$BUILD_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"bun run server.js"* ]]
}

@test "release: falls back to dist/index.js (pre-bundled mode)" {
  create_package_json "$BUILD_DIR" '{"name":"test","version":"1.0.0"}'
  create_node_modules "$BUILD_DIR" hono
  mkdir -p "${BUILD_DIR}/dist"
  touch "${BUILD_DIR}/dist/index.js"

  run "${BUILDPACK_DIR}/bin/release" "$BUILD_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"bun run dist/index.js"* ]]
}

@test "release: falls back to server.js (pre-bundled mode)" {
  create_package_json "$BUILD_DIR" '{"name":"test","version":"1.0.0"}'
  create_node_modules "$BUILD_DIR" hono
  touch "${BUILD_DIR}/server.js"

  run "${BUILDPACK_DIR}/bin/release" "$BUILD_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"bun run server.js"* ]]
}

@test "release: falls back to index.js (pre-bundled mode)" {
  create_package_json "$BUILD_DIR" '{"name":"test","version":"1.0.0"}'
  create_node_modules "$BUILD_DIR" hono
  touch "${BUILD_DIR}/index.js"

  run "${BUILDPACK_DIR}/bin/release" "$BUILD_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"bun run index.js"* ]]
}

@test "release: emits no web process type when nothing found (pre-bundled mode)" {
  create_package_json "$BUILD_DIR" '{"name":"test","version":"1.0.0"}'
  create_node_modules "$BUILD_DIR" hono

  run "${BUILDPACK_DIR}/bin/release" "$BUILD_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"default_process_types: {}"* ]]
}

# ── Single-file mode (no node_modules) ──────────────────────────

@test "release: uses scripts.start (single-file mode)" {
  create_package_json "$BUILD_DIR" '{"name":"test","version":"1.0.0","scripts":{"start":"bun run dist/app.js"}}'

  run "${BUILDPACK_DIR}/bin/release" "$BUILD_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"bun run dist/app.js"* ]]
}

@test "release: emits no web process type when scripts.start absent (single-file mode)" {
  create_package_json "$BUILD_DIR" '{"name":"test","version":"1.0.0"}'

  run "${BUILDPACK_DIR}/bin/release" "$BUILD_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"default_process_types: {}"* ]]
}

# ── Common ───────────────────────────────────────────────────────

@test "release: JSON-escapes quotes in start command" {
  create_package_json "$BUILD_DIR" '{"name":"test","version":"1.0.0","scripts":{"start":"bun -e \"console.log(1)\""}}'
  create_node_modules "$BUILD_DIR" hono

  run "${BUILDPACK_DIR}/bin/release" "$BUILD_DIR"
  [ "$status" -eq 0 ]
  # The JSON-escaped value should contain escaped quotes
  [[ "$output" == *'\"'* ]]
}

@test "release: output is valid YAML" {
  create_package_json "$BUILD_DIR"
  create_node_modules "$BUILD_DIR" hono

  run "${BUILDPACK_DIR}/bin/release" "$BUILD_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"---"* ]]
  [[ "$output" == *"default_process_types:"* ]]
  [[ "$output" == *"web:"* ]]
}
