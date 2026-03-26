#!/usr/bin/env bats
# ================================================================
# Tests for lib/utils.sh
# ================================================================

load test_helper/common_setup

setup() {
  setup_common
}

teardown() {
  teardown_common
}

# ── resolve_bun_version ──────────────────────────────────────────

@test "resolve_bun_version: exact version passes through" {
  run resolve_bun_version "1.2.9"
  [ "$output" = "1.2.9" ]
}

@test "resolve_bun_version: empty string returns default" {
  run resolve_bun_version ""
  [ "$output" = "1.2.9" ]
}

@test "resolve_bun_version: ^1.2.9 strips prefix" {
  run resolve_bun_version "^1.2.9"
  [ "$output" = "1.2.9" ]
}

@test "resolve_bun_version: ~1.2.9 strips prefix" {
  run resolve_bun_version "~1.2.9"
  [ "$output" = "1.2.9" ]
}

@test "resolve_bun_version: >=1.2.9 strips prefix" {
  run resolve_bun_version ">=1.2.9"
  [ "$output" = "1.2.9" ]
}

@test "resolve_bun_version: rejects major only (1)" {
  run resolve_bun_version "1"
  [ "$status" -eq 1 ]
}

@test "resolve_bun_version: rejects major.minor (1.2)" {
  run resolve_bun_version "1.2"
  [ "$status" -eq 1 ]
}

@test "resolve_bun_version: rejects wildcards (1.x)" {
  run resolve_bun_version "1.x"
  [ "$status" -eq 1 ]
}

@test "resolve_bun_version: rejects wildcards (1.2.x)" {
  run resolve_bun_version "1.2.x"
  [ "$status" -eq 1 ]
}

@test "resolve_bun_version: rejects range with space (>=1 <2)" {
  run resolve_bun_version ">=1 <2"
  [ "$status" -eq 1 ]
}

@test "resolve_bun_version: rejects OR range (1 || 2)" {
  run resolve_bun_version "1 || 2"
  [ "$status" -eq 1 ]
}

@test "resolve_bun_version: rejects hyphen range (1 - 2)" {
  run resolve_bun_version "1 - 2"
  [ "$status" -eq 1 ]
}

@test "resolve_bun_version: rejects lone star (*)" {
  run resolve_bun_version "*"
  [ "$status" -eq 1 ]
}

# ── read_package_field ───────────────────────────────────────────

@test "read_package_field: reads top-level field" {
  create_package_json "$BUILD_DIR"
  run read_package_field "${BUILD_DIR}/package.json" "name"
  [ "$output" = "test-app" ]
}

@test "read_package_field: reads nested field (engines.bun)" {
  create_package_json "$BUILD_DIR"
  run read_package_field "${BUILD_DIR}/package.json" "engines.bun"
  [ "$output" = "1.2.9" ]
}

@test "read_package_field: reads scripts.start" {
  create_package_json "$BUILD_DIR"
  run read_package_field "${BUILD_DIR}/package.json" "scripts.start"
  [ "$output" = "bun run server.js" ]
}

@test "read_package_field: returns empty for missing field" {
  create_package_json "$BUILD_DIR"
  run read_package_field "${BUILD_DIR}/package.json" "nonexistent"
  [ "$output" = "" ]
}

@test "read_package_field: returns empty for missing file" {
  run read_package_field "${BUILD_DIR}/missing.json" "name"
  [ "$output" = "" ]
}

# ── read_first_dependency ────────────────────────────────────────

@test "read_first_dependency: returns first dependency" {
  create_package_json "$BUILD_DIR"
  run read_first_dependency "${BUILD_DIR}/package.json"
  [ "$output" = "hono" ]
}

@test "read_first_dependency: returns empty when no dependencies" {
  create_package_json "$BUILD_DIR" '{"name":"test","version":"1.0.0"}'
  run read_first_dependency "${BUILD_DIR}/package.json"
  [ "$output" = "" ]
}

@test "read_first_dependency: returns empty for missing file" {
  run read_first_dependency "${BUILD_DIR}/missing.json"
  [ "$output" = "" ]
}
