#!/usr/bin/env bats
# ================================================================
# Tests for bin/detect
# ================================================================

load test_helper/common_setup

setup() {
  setup_common
}

teardown() {
  teardown_common
}

@test "detect: succeeds with bun.lockb" {
  create_bun_lockb "$BUILD_DIR"

  run "${BUILDPACK_DIR}/bin/detect" "$BUILD_DIR"
  [ "$status" -eq 0 ]
  [ "$output" = "bun" ]
}

@test "detect: succeeds with bun.lock (Bun 1.2+)" {
  create_bun_lock "$BUILD_DIR"

  run "${BUILDPACK_DIR}/bin/detect" "$BUILD_DIR"
  [ "$status" -eq 0 ]
  [ "$output" = "bun" ]
}

@test "detect: succeeds with bunfig.toml" {
  create_bunfig_toml "$BUILD_DIR"

  run "${BUILDPACK_DIR}/bin/detect" "$BUILD_DIR"
  [ "$status" -eq 0 ]
  [ "$output" = "bun" ]
}

@test "detect: succeeds with engines.bun in package.json" {
  create_package_json "$BUILD_DIR"

  run "${BUILDPACK_DIR}/bin/detect" "$BUILD_DIR"
  [ "$status" -eq 0 ]
  [ "$output" = "bun" ]
}

@test "detect: fails when no Bun markers present" {
  # Empty build dir
  run "${BUILDPACK_DIR}/bin/detect" "$BUILD_DIR"
  [ "$status" -eq 1 ]
  [[ "$output" == *"No Bun markers found"* ]]
}

@test "detect: fails with package.json without engines.bun" {
  create_package_json "$BUILD_DIR" '{"name":"test","version":"1.0.0","engines":{"node":"20"}}'

  run "${BUILDPACK_DIR}/bin/detect" "$BUILD_DIR"
  [ "$status" -eq 1 ]
}

@test "detect: does NOT require node_modules for detection" {
  # Only bun.lockb, no node_modules
  create_bun_lockb "$BUILD_DIR"

  run "${BUILDPACK_DIR}/bin/detect" "$BUILD_DIR"
  [ "$status" -eq 0 ]
  [ "$output" = "bun" ]
}
